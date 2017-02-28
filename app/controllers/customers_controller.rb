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
class CustomersController < ApplicationController
  load_and_authorize_resource

  before_action :set_customer, only: [:edit, :update, :delete_vehicle]
  before_action :clear_customer_params, only: [:create, :update]

  include Devices::Helpers

  def index
    @customers = current_user.reseller.customers.order(:name)
  end

  def new
    @customer = current_user.reseller.customers.build
  end

  def edit
  end

  def create
    @customer = current_user.reseller.customers.build(customer_params)
    respond_to do |format|
      if @customer.save
        format.html { redirect_to edit_customer_path(@customer), notice: t('activerecord.successful.messages.created', model: @customer.class.model_name.human) }
      else
        format.html { render action: 'new' }
      end
    end
  end

  def update
    @customer.assign_attributes(customer_params)
    @customer.update_columns(devices: customer_params[:devices])
    respond_to do |format|
      if @customer.save
        format.html { redirect_to edit_customer_path(@customer), notice: t('activerecord.successful.messages.updated', model: @customer.class.model_name.human) }
      else
        format.html { render action: 'edit' }
      end
    end
  end

  def destroy
    @customer.destroy
    redirect_to customers_path, notice: t('.success')
  end

  def destroy_multiple
    current_user.reseller.customers.find(params[:customers].keys).each(&:destroy) if params[:customers]
    redirect_to customers_path, notice: t('.success')
  end

  def delete_vehicle
    if current_user.admin? || !Mapotempo::Application.config.manage_vehicles_only_admin
      @customer.vehicles.find(params[:vehicle_id]).destroy
    end
    redirect_to [:edit, @customer], notice: t('.success')
  end

  def duplicate
    @customer.duplicate.save!
    redirect_to [:customers], notice: t('.success')
  end

  private

  def set_customer
    @customer = current_user.admin? ? current_user.reseller.customers.find(params[:id]) : current_user.customer
  end

  def clear_customer_params # Delete default password displayed in form
    params[:customer].delete(:tomtom_password) if params[:customer][:tomtom_password].blank?
    params[:customer].delete(:teksat_password) if params[:customer][:teksat_password].blank?
    params[:customer].delete(:orange_password) if params[:customer][:orange_password].blank?
  end

  def customer_params
    if params[:customer][:router]
      params[:customer][:router_id], params[:customer][:router_dimension] = params[:customer][:router].split('_')
    end
    if current_user.admin?
      p = params.require(:customer).permit(:ref, :name, :end_subscription, :max_vehicles, :take_over, :print_planning_annotating, :print_header, :router_id, :router_dimension, :speed_multiplicator, :enable_orders, :test, :optimization_cluster_size, :optimization_time, :optimization_stop_soft_upper_bound, :optimization_vehicle_soft_upper_bound, :profile_id, :default_country, :enable_multi_vehicle_usage_sets, :print_stop_time, :enable_references, :enable_multi_visits, :print_map, :enable_external_callback, :external_callback_url, :external_callback_name, :description, :enable_global_optimization, :enable_vehicle_position, :enable_stop_status, devices: permit_recursive_params(params[:customer][:devices]))
      p[:end_subscription] = Date.strptime(p[:end_subscription], I18n.t('time.formats.datepicker')).strftime(ACTIVE_RECORD_DATE_MASK) if !p[:end_subscription].blank?
      p
    else
      allowed_params = [:take_over, :print_planning_annotating, :print_header, :router_id, :router_dimension, :speed_multiplicator, com_api_key, :default_country, :print_stop_time, :print_map, :external_callback_url, :external_callback_name, devices: permit_recursive_params(params[:customer][:devices])]
      allowed_params << :max_vehicles if !Mapotempo::Application.config.manage_vehicles_only_admin
      params.require(:customer).permit(*allowed_params)
    end
  end

  def permit_recursive_params(params)
    if !params.nil? 
      params.map do |key, value|
        if value.is_a?(Array)
          { key => [ permit_recursive_params(value.first) ] }
        elsif value.is_a?(Hash) || value.is_a?(ActionController::Parameters)
          { key => permit_recursive_params(value) }
        else
          key
        end
      end
    end
  end

end
