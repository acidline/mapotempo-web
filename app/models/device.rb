# Copyright © Mapotempo, 2013-2015
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
require 'value_to_boolean'

class Device

  def initialize(customer)
  	@customer = customer
  end

  def devices_list
    devices = []
    Mapotempo::Application.config.devices.to_h.each{ |device_name, device_object|
      if(device_object.respond_to?('definition'))
        devices << device_object.definition
      end
    }
    devices
  end

  def check_device(device_name)
    active = false
    if !enabled_devices_list.nil? && enabled_devices_list.key?(device_name)
      enabled_devices_list[device_name].each{ |k, v| 
        active = !v.blank? ? true : false;
      }
    end
    active
  end

  def available_position?
    ready_position = false
    devices_list.each{ |d|
      if check_device(d[:device])
        ready_position = true
        break
      end
    }
    @customer.enable_vehicle_position? && ready_position
  end

  def available_stop_status?
    @customer.enable_stop_status?
  end

  def enabled_devices_list
    @customer.devices.select{ |device, conf| conf[:enable] == "true" } if !@customer.devices.nil?
  end

  def render_form(device, form_name, key, form, model)

    html_form = ""
  
    if device[:forms].key?(form_name)

        device[:forms][form_name].each do |element|

          name = key + '['+ element[1] + ']'
              
          html_form += '<div class="form-group">'
          html_form += form.label_tag name, I18n.t(device[:translate][form_name][:label], :default => element[1].capitalize), class: 'col-md-2 control-label'
          html_form += '<div class="col-md-6 input-append">'
        
          case element[0]
            when :text
              html_form += form.text_field_tag name, nil, id: nil, style: "display:none;"
              html_form += form.text_field_tag name, model.device_json_value(device[:device], element[1]), autocomplete: "off", class: "form-control"
            when :select
              html_form +=  form.select_tag name, [], id: nil, style: "display:none;"
              html_form += form.select_tag name, []
            when :password
              html_form += form.password_field_tag name, nil, id: nil, style: "display:none;"
              html_form += form.password_field_tag name, model.device_json_value(device[:device], element[1]), autocomplete: "off", class: "form-control"
          end
                
          html_form += '</div>'
          html_form += '</div>'

        end
    end

    html_form.html_safe

  end

end
