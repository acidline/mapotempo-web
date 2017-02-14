# Copyright © Mapotempo, 2016
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
require 'addressable'

class Teksat < DeviceBase

  attr_accessor :ticket_id

  def get_device_definition
    {
      device: 'teksat',
      label: 'Teksat',
      image_url: 'https://www.teksat.fr/wp-content/uploads/2016/06/logo-teksat.png',
      has_sync: true,
      translate: {
        enable: 'activerecord.attributes.customer.devices.teksat.enable',
        help: 'customers.form.devices.teksat_help',
        sync: 'customers.form.devices.sync.teksat.action',
        admin_vehicle_label: 'activerecord.attributes.vehicle.devices.teksat.label',
      },
      forms: {
        admin_customer: [
          [:text, 'customer_id'],
          [:text, 'url'],
          [:text, 'username'],
          [:password, 'password']
        ],
        admin_vehicle: [
          [:select, 'teksat_id'],
        ],
      }
    }
  end

  def check_auth(params, customer)
    authenticate(customer, params)
  end

  def authenticate(customer, params)

    url          = params[:teksat_url]         ? params[:teksat_url]         : customer.devices[:teksat][:url]
    customer_id  = params[:teksat_customer_id] ? params[:teksat_customer_id] : customer.devices[:teksat][:customer_id]
    username     = params[:teksat_username]    ? params[:teksat_username]    : customer.devices[:teksat][:username]
    password     = params[:teksat_password]    ? params[:teksat_password]    : customer.devices[:teksat][:password]

    auth = { auth: { url: url, customer_id: customer_id, username: username, password: password } }

    response = RestClient.get get_ticket_url(customer, auth)
    if response.code == 200 && response.strip.length >= 1
      return response.strip
    else
      raise DeviceServiceError.new('Teksat: %s' % [I18n.t('errors.teksat.get_ticket')])
    end
  rescue RestClient::Forbidden, RestClient::InternalServerError
    raise DeviceServiceError.new('Teksat: %s' % [I18n.t('errors.teksat.unauthorized')])
  end

  def list_devices(customer)
    response = RestClient.get get_vehicles_url(customer)
    if response.code == 200
      Nokogiri::XML(response).xpath('//vehicle').map do |item|
        { id: item['id'], text: '%s %s - %s' % [item['brand'], item['type'], item['code']] }
      end
    else
      raise DeviceServiceError.new('Teksat: %s' % [I18n.t('errors.teksat.list')])
    end
  end

  def send_route(customer, route, _options = {})
    send_mission(customer, route, route.start, route.vehicle_usage.default_store_start) if route.vehicle_usage.default_store_start
    route.stops.select(&:active?).select(&:position?).sort_by(&:index).each do |stop|
      next if !stop.time # Teksat API: Stop time is required
      send_mission(customer, route, stop.time, stop)
    end
    send_mission(customer, route, route.end, route.vehicle_usage.default_store_stop) if route.vehicle_usage.default_store_stop
  end

  def clear_route(customer, route)
    response = RestClient.get get_missions_url(customer, date: planning_date(route.planning).strftime('%Y-%m-%d'))
    Nokogiri::XML(response).xpath('//mission').map{ |item| RestClient.get(delete_mission_url(customer, mi_id: item['id'])) }
  end

  def get_vehicles_pos(customer)
    response = RestClient.get get_vehicles_pos_url(customer)
    if response.code == 200
      Nokogiri::XML(response).xpath('//vehicle_pos').map do |item|
        { teksat_vehicle_id: item['v_id'], lat: item['lat'], lng: item['lng'], speed: item['speed'], time: item['data_time_gmt'] + '+00:00', device_name: item['code'] }
      end
    else
      raise DeviceServiceError.new('Teksat: %s' % [I18n.t('errors.teksat.get_vehicles_pos')])
    end
  end

  private

  def send_mission(customer, route, start_time, destination)
    response = RestClient.get set_mission_url(customer, {
      mi_v_id: route.vehicle_usage.vehicle.teksat_id,
      mi_label: route.planning.name,
      mi_customer: destination.name,
      mi_begin_latitude: destination.lat,
      mi_begin_longitude: destination.lng,
      mi_begin_address1: destination.street,
      mi_begin_zip: destination.postalcode,
      mi_begin_city: destination.city,
      mi_begin_country: destination.country || customer.default_country,
      mi_begin_date: p_time(route, start_time).strftime('%Y-%m-%d'),
      mi_begin_time: p_time(route, start_time).strftime('%H:%M:%S')
    })
    if response.code != 200
      raise DeviceServiceError.new('Teksat: %s' % [I18n.t('errors.teksat.set_mission')])
    end
  end

  def get_ticket_url(customer, options = {})
    if options[:auth]
      url, customer_id, username, password = options[:auth][:url], options[:auth][:customer_id], options[:auth][:username], options[:auth][:password]
    else
      url, customer_id, username, password = customer.devices[:teksat][:url], customer.devices[:teksat][:customer_id], customer.devices[:teksat][:username], customer.devices[:teksat][:password]
    end
    if (url =~ /\A(www.*.teksat.fr)\Z/).nil?
      raise DeviceServiceError.new('Teksat: %s' % [I18n.t('errors.teksat.bad_url')])
    end
    Addressable::Template.new('http://%s/webservices/map/get-ticket.jsp{?query*}' % [url]).expand(
      query: { custID: customer_id, username: username, pw: password }
    ).to_s
  end

  def get_vehicles_url(customer)
    Addressable::Template.new('http://%s/webservices/map/get-vehicles.jsp{?query*}' % [customer.devices[:teksat][:url]]).expand(
      query: { custID: customer.devices[:teksat][:customer_id], tck: ticket_id }
    ).to_s
  end

  def get_vehicles_pos_url(customer)
    Addressable::Template.new('http://%s/webservices/map/get-vehicles-pos.jsp{?query*}' % [customer.devices[:teksat][:url]]).expand(
      query: { custID: customer.teksat_customer_id, tck: ticket_id }
    ).to_s
  end

  def set_mission_url(customer, options)
    Addressable::Template.new('http://%s/webservices/map/set-mission.jsp{?query*}' % [customer.devices[:teksat][:url]]).expand(
      query: options.merge(custID: customer.devices[:teksat][:customer_id], tck: ticket_id)
    ).to_s
  end

  def get_missions_url(customer, options)
    Addressable::Template.new('http://%s/webservices/map/get-missions.jsp{?query*}' % [customer.devices[:teksat][:url]]).expand(
      query: options.merge(custID: customer.devices[:teksat][:customer_id], tck: ticket_id)
    ).to_s
  end

  def delete_mission_url(customer, options)
    Addressable::Template.new('http://%s/webservices/map/delete-mission.jsp{?query*}' % [customer.devices[:teksat][:url]]).expand(
      query: options.merge(custID: customer.devices[:teksat][:customer_id], tck: ticket_id)
    ).to_s
  end

end
