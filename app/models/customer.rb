# Copyright © Mapotempo, 2013-2016
#
# This file is part of Mapotempo.
#
# Mapotempo is free software. You can redistribute it and/or
# modify since you respect the terms of the GNU Affero General
# Public License as published by the Free Software Foundation,
# either version 3 of the License, or (at your option) any later version.
#
# Mapotempo is distributed in the hope that it will be useful, but WITHOUT
# ANY WARRANTY; without even the implied warranty of MERCHANTABILITY
# or FITNESS FOR A PARTICULAR PURPOSE.  See the Licenses for more details.
#
# You should have received a copy of the GNU Affero General Public License
# along with Mapotempo. If not, see:
# <http://www.gnu.org/licenses/agpl.html>
#
require 'sanitize'

class Customer < ActiveRecord::Base
  belongs_to :reseller
  belongs_to :profile
  belongs_to :router
  belongs_to :job_destination_geocoding, class_name: 'Delayed::Backend::ActiveRecord::Job', dependent: :destroy
  belongs_to :job_store_geocoding, class_name: 'Delayed::Backend::ActiveRecord::Job', dependent: :destroy
  belongs_to :job_optimizer, class_name: 'Delayed::Backend::ActiveRecord::Job', dependent: :destroy
  has_many :products, -> { order('code') }, inverse_of: :customer, autosave: true, dependent: :delete_all
  has_many :plannings, -> { includes(:tags).order('id') }, inverse_of: :customer, autosave: true, dependent: :delete_all
  has_many :order_arrays, -> { order('id') }, inverse_of: :customer, autosave: true, dependent: :delete_all
  has_many :zonings, inverse_of: :customer, dependent: :delete_all
  before_destroy :destroy_disable_vehicle_usage_sets_validation # Declare and run before has_many :vehicle_usage_sets
  has_many :vehicle_usage_sets, -> { order('id') }, inverse_of: :customer, autosave: true, dependent: :destroy
  has_many :vehicles, -> { order('id') }, inverse_of: :customer, autosave: true, dependent: :delete_all
  has_many :stores, -> { order('id') }, inverse_of: :customer, autosave: true, dependent: :delete_all
  has_many :destinations, -> { order('id') }, inverse_of: :customer, autosave: true, dependent: :delete_all
  has_many :tags, -> { order('label') }, inverse_of: :customer, autosave: true, dependent: :delete_all
  has_many :users, -> { order('LOWER(email)') }, inverse_of: :customer, dependent: :destroy
  has_many :deliverable_units, -> { order('id') }, inverse_of: :customer, autosave: true, dependent: :delete_all, after_add: :update_deliverable_units_track, after_remove: :update_deliverable_units_track
  enum router_dimension: Router::DIMENSION

  attr_accessor :deliverable_units_updated, :devices

  nilify_blanks
  # auto_strip_attributes :name, :tomtom_account, :tomtom_user, :tomtom_password, :print_header, :masternaut_user, :masternaut_password, :alyacom_association, :default_country
  auto_strip_attributes :name, :print_header,  :default_country
  validates :ref, uniqueness: { scope: :reseller_id, case_sensitive: true }, allow_nil: true, allow_blank: true
  validates :profile, presence: true
  validates :router, presence: true
  validates :router_dimension, presence: true
  validates :name, presence: true
  validates :default_country, presence: true
  validates :stores, length: { maximum: Mapotempo::Application.config.max_destinations / 10, message: :over_max_limit }
  validates :destinations, length: { maximum: Mapotempo::Application.config.max_destinations, message: :over_max_limit }
  validates :optimization_cluster_size, numericality: { greater_than_or_equal_to: 0 }, allow_nil: true
  validates :max_vehicles, numericality: { greater_than: 0 }
  validate do
    errors.add(:max_vehicles, :not_an_integer) if @invalid_max_vehicle
    !@invalid_max_vehicle
  end
  validates :speed_multiplicator, numericality: { greater_than_or_equal_to: 0.5, less_than_or_equal_to: 1.5 }, if: :speed_multiplicator

  after_initialize :assign_defaults, :update_max_vehicles, if: 'new_record?'
  after_create :create_default_store, :create_default_vehicle_usage_set, :create_default_deliverable_unit
  before_update :update_out_of_date, :update_max_vehicles, :update_enable_multi_visits
  before_save :sanitize_print_header
  
  # ==> NICOLAS TEST before_save :devices_update_vehicles, prepend: true
  # serialize :devices, HashWithIndifferentAccess

  include RefSanitizer

  amoeba do
    nullify :job_destination_geocoding_id
    nullify :job_store_geocoding_id
    nullify :job_optimizer_id
    nullify :ref

    # No duplication of OrderArray
    exclude_association :products
    exclude_association :order_arrays
    exclude_association :ref

    customize(lambda { |original, copy|
      def copy.assign_defaults; end

      def copy.update_max_vehicles; end

      def copy.create_default_store; end

      def copy.create_default_vehicle_usage_set; end

      def copy.create_default_deliverable_unit; end

      def copy.update_out_of_date; end

      def copy.update_enable_multi_visits; end

      def copy.sanitize_print_header; end

      def copy.devices_update_vehicles; end

      copy.save!

      deliverable_unit_ids_map = Hash[original.deliverable_units.map(&:id).zip(copy.deliverable_units)].merge(nil => nil)
      vehicles_map = Hash[original.vehicles.zip(copy.vehicles)].merge(nil => nil)
      vehicle_usage_sets_map = Hash[original.vehicle_usage_sets.zip(copy.vehicle_usage_sets)].merge(nil => nil)
      vehicle_usages_map = Hash[original.vehicle_usage_sets.collect(&:vehicle_usages).flatten.zip(copy.vehicle_usage_sets.collect(&:vehicle_usages).flatten)].merge(nil => nil)
      stores_map = Hash[original.stores.zip(copy.stores)].merge(nil => nil)
      visits_map = Hash[original.destinations.collect(&:visits).flatten.zip(copy.destinations.collect(&:visits).flatten)].merge(nil => nil)
      tags_map = Hash[original.tags.zip(copy.tags)].merge(nil => nil)
      zonings_map = Hash[original.zonings.zip(copy.zonings)].merge(nil => nil)

      copy.vehicles.each{ |vehicle|
        vehicle.capacities = Hash[vehicle.capacities.to_a.map{ |q| deliverable_unit_ids_map[q[0]] && [deliverable_unit_ids_map[q[0]].id, q[1]]}.compact]
        vehicle.save!
      }

      copy.vehicle_usage_sets.each{ |vehicle_usage_set|
        vehicle_usage_set.store_start = stores_map[vehicle_usage_set.store_start]
        vehicle_usage_set.store_stop = stores_map[vehicle_usage_set.store_stop]
        vehicle_usage_set.store_rest = stores_map[vehicle_usage_set.store_rest]

        vehicle_usage_set.vehicle_usages.each{ |vehicle_usage|
          vehicle_usage.vehicle = vehicles_map[vehicle_usage.vehicle]
          vehicle_usage.store_start = stores_map[vehicle_usage.store_start]
          vehicle_usage.store_stop = stores_map[vehicle_usage.store_stop]
          vehicle_usage.store_rest = stores_map[vehicle_usage.store_rest]
          vehicle_usage.save!
        }
        vehicle_usage_set.save!
      }

      copy.destinations.each{ |destination|
        destination.tags = destination.tags.collect{ |tag| tags_map[tag] }

        destination.visits.each{ |visit|
          visit.tags = visit.tags.collect{ |tag| tags_map[tag] }
          visit.quantities = Hash[visit.quantities.to_a.map{ |q| deliverable_unit_ids_map[q[0]] && [deliverable_unit_ids_map[q[0]].id, q[1]]}.compact]
          visit.save!
        }
        destination.save!
      }

      copy.zonings.each{ |zoning|
        zoning.zones.each{ |zone|
          zone.vehicle = vehicles_map[zone.vehicle]
          zone.save!
        }
      }

      copy.plannings.each{ |planning|
        planning.vehicle_usage_set = vehicle_usage_sets_map[planning.vehicle_usage_set]
        planning.zonings = planning.zonings.collect{ |zoning| zonings_map[zoning] }
        planning.tags = planning.tags.collect{ |tag| tags_map[tag] }

        planning.routes.each{ |route|
          route.vehicle_usage = vehicle_usages_map[route.vehicle_usage]

          route.stops.each{ |stop|
            stop.visit = visits_map[stop.visit]
            stop.save!
          }
          route.save!
        }
        planning.save!
      }

      copy.save!
      copy.reload
    })
  end

  def devices
    self[:devices].deep_symbolize_keys
  end

  def duplicate
    Customer.transaction do
      copy = self.amoeba_dup
      copy.name += " (#{I18n.l(Time.zone.now, format: :long)})"
      copy.ref = copy.ref ? Time.new.to_i.to_s : nil
      copy.test = Mapotempo::Application.config.customer_test_default
      copy.save!
      copy
    end
  end

  def default_position
    store = stores.find{ |s| !s.lat.nil? && !s.lng.nil? }
    # store ? [store.lat, store.lng] : [I18n.t('stores.default.lat'), I18n.t('stores.default.lng')]
    {lat: store ? store.lat : I18n.t('stores.default.lat'), lng: store ? store.lng : I18n.t('stores.default.lng')}
  end

  def max_vehicles
    @max_vehicles ||= vehicles.size
  end

  def max_vehicles=(max)
    if !max.blank?
      @max_vehicles = Integer(max.to_s, 10)
    end
  rescue ArgumentError
    @invalid_max_vehicle = true
  end

  def visits
    destinations.collect(&:visits).flatten
  end

  def delete_all_destinations
    destinations.delete_all
    plannings.each { |p|
      p.routes.select(&:vehicle_usage).each do |route|
        # reindex remaining stops (like rests)
        route.force_reindex
        # out_of_date for last step
        route.out_of_date = true if route.stop_trace
        route.optimized_at = route.last_sent_to = route.last_sent_at = nil
      end
      p.save!
    }
  end

  def get_json_value(device, key)
    devices[device.to_sym][key.to_sym]
  end

  def enabled_devices_list
    devices.select{ |device, conf| conf[:enable] == "true" }
  end

  def get_devices_list
    devices = []
    Mapotempo::Application.config.devices.to_h.each{ |device_name, device_object|
      devices << device_object.get_device_definition
    }
    devices
  end

  def check_device(device_name)
    enabled_devices = get_enabled_devices_list
    active = false

    if enabled_devices.key?(device_name)
      enabled_devices[device_name].each{ |k, v| 
        active = !v.blank? ? true : false;
      }
    end

    active
  end

  # Alias / Shortcut to check_device
  def masternaut?
    check_device :masternaut
  end

  def alyacom?
    check_device :alyacom
  end

  def tomtom?
    check_device :tomtom
  end

  def teksat?
    check_device :teksat
  end

  def orange?
    check_device :orange
  end

  def trimble?
    check_device :trimble
  end

  def locster?
    check_device :locster
  end

  def suiviDeFlotte?
    check_device :suiviDeFlotte
  end


  private

  def devices_update_vehicles
    # Remove device association on vehicles
    self.vehicles.select(&:tomtom_id).each{ |vehicle| vehicle.tomtom_id = nil } if !self.enable_tomtom || (self.tomtom_account_changed? && !self.tomtom_account_was.nil?) || (self.tomtom_user_changed? && !self.tomtom_user_was.nil?)
    self.vehicles.select(&:teksat_id).each{ |vehicle| vehicle.teksat_id = nil } if !self.enable_teksat || (self.teksat_customer_id_changed? && !self.teksat_customer_id_was.nil?) || (self.teksat_username_changed? && !self.teksat_username_was.nil?)
    self.vehicles.select(&:orange_id).each{ |vehicle| vehicle.orange_id = nil } if !self.enable_orange || (self.orange_user_changed? && !self.orange_user_was.nil?)
  end

  def assign_defaults
    self.default_country ||= I18n.t('customers.default.country')
    self.enable_references = Mapotempo::Application.config.enable_references
    self.enable_multi_visits = Mapotempo::Application.config.enable_multi_visits
    self.test = Mapotempo::Application.config.customer_test_default
  end

  def create_default_store
    stores.create(
      name: I18n.t('stores.default.name'),
      city: I18n.t('stores.default.city'),
      lat: Float(I18n.t('stores.default.lat')),
      lng: Float(I18n.t('stores.default.lng'))
    )
  end

  def create_default_vehicle_usage_set
    vehicle_usage_sets.create(
      name: I18n.t('vehicle_usage_sets.default.name'),
      store_start: stores[0],
      store_stop: stores[0]
    )
  end

  def create_default_deliverable_unit
    deliverable_units.create(
      default_quantity: 1
    )
  end

  def update_out_of_date
    if take_over_changed? || router_id_changed? || router_dimension_changed? || speed_multiplicator_changed? || @deliverable_units_updated
      Route.transaction do
        plannings.each{ |planning|
          planning.routes.each{ |route|
            route.out_of_date = true
            route.optimized_at = route.last_sent_to = route.last_sent_at = nil
          }
        }
      end
    end
  end

  def update_deliverable_units_track(_deliverable_unit)
    @deliverable_units_updated = true
  end

  def update_max_vehicles
    if max_vehicles != vehicles.size
      if vehicles.size < max_vehicles
        # Add new
        (max_vehicles - vehicles.size).times{ |_i|
          vehicle = vehicles.build(name: I18n.t('vehicles.default_name', n: vehicles.size + 1))
          vehicle.color = COLORS_TABLE[(vehicles.size - 1) % COLORS_TABLE.size]
        }
      elsif vehicles.size > max_vehicles
        # Delete
        (vehicles.size - max_vehicles).times{ |_i|
          vehicle = vehicles[vehicles.size - 1]
          vehicles.destroy(vehicle)
        }
      end
      @max_vehicles = vehicles.size
    end
  end

  def update_enable_multi_visits
    if enable_multi_visits_changed?
      Destination.transaction do
        if enable_multi_visits
          self.destinations.each{ |destination|
            destination.visits.each{ |visit|
              visit.ref = destination.ref
              visit.tags = destination.tags # ?
            }
            destination.ref = nil
            destination.tag_ids = []
          }
        else
          self.destinations.select(&:present?).each{ |destination|
            destination.ref = destination.visits[0].ref
            destination.tags = destination.visits[0].tags # ?
            destination.visits.each{ |visit|
              visit.ref = nil
              visit.tag_ids = []
            }
          }
        end
      end
    end
  end

  def sanitize_print_header
    self.print_header = Sanitize.fragment(print_header, Sanitize::Config::RELAXED)
  end

  def destroy_disable_vehicle_usage_sets_validation
    vehicle_usage_sets.each{ |vehicle_usage_set|
      def vehicle_usage_set.destroy_vehicle_usage_set
        # Avoid validation of at least one vehicle_usage_set by customer
      end
    }
  end
end
