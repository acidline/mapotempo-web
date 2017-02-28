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
module Interface

  class InterfaceNotImplementedError < NoMethodError
  end

  def method(name)
    define_method(name) { |*args|
			raise Interface::InterfaceNotImplementedError.new("#{self.class.name} needs to implement '#{name}' for interface DeviceInterface !")
    }
  end

end

module DeviceInterface
  extend Interface
  method :get_device_definition
  method :check_auth
end


class DeviceBase

	include DeviceInterface

  attr_accessor :api_url, :api_key

  def planning_date(planning)
    planning.date ? planning.date.beginning_of_day : Time.zone.now.beginning_of_day
  end

  def p_time(route, time)
    planning_date(route.planning) + (time.utc - Time.utc(2000, 1, 1, 0, 0))
  end

end

class DeviceServiceError < StandardError; end
