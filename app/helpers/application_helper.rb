# Copyright © Mapotempo, 2013-2014
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
require "awesome_print"
require 'pp'
require "value_to_boolean"

module ApplicationHelper
  def span_tag(content)
    content_tag :span, content, class: 'default-color'
  end

  def number_to_human(number, options = {})
    options.merge! delimiter: I18n.t('number.format.delimiter'), separator: I18n.t('number.format.separator'), strip_insignificant_zeros: true
    super number, options
  end

  def customised_color_verification(data)
    if data.nil?
      DEFAULT_COLOR
    elsif COLORS_TABLE.include? data
      DEFAULT_COLOR
    else
      data
    end
  end

  def locale_distance(distance, unit = 'km', options = {})
    base_options = { units: :distance, precision: 3, format: '%n %u' }
    options.merge!(base_options)

    if !unit.nil? && unit != 'km'
      distance = distance / 1.609344
      options[:units] = :distance_miles
    end

    if !options[:display_unit].nil? && !options[:display_unit]
      options.except!(:units)
    end

    number_to_human(distance, options)
  end

  def to_bool(str)
    ValueToBoolean.value_to_boolean str
  end

end


def dump(object, label = nil)

  time = Time.new
  debugdateTime = "DEBUG : " + time.strftime("%Y-%m-%d %H:%M:%S")
  debugdateTimeColored = "#{colorize(debugdateTime, "white", "light red")}"

  case object
    when String
      puts debugdateTimeColored + " : " + colorize(object, "yellow")

    else
      if !label.nil?
        puts debugdateTimeColored + "\n #{colorize(label, "yellow")}"  + "\n"
      else
        puts debugdateTimeColored + " : \n"
      end
      pp object
      puts "\n"
  end

end

def colorize(text, color = "default", bgColor = "default")

    colors = {
      "default" => "38",
      "black" => "30",
      "red" => "31",
      "green" => "32",
      "brown" => "33",
      "blue" => "34",
      "purple" => "35",
      "cyan" => "36",
      "gray" => "37",
      "dark gray" => "1;30",
      "light red" => "1;31",
      "light green" => "1;32",
      "yellow" => "1;33",
      "light blue" => "1;34",
      "light purple" => "1;35",
      "light cyan" => "1;36",
      "white" => "1;37"
    }
    bgColors = {
      "default" => "0",
      "black" => "40",
      "red" => "41",
      "green" => "42",
      "brown" => "43",
      "blue" => "44",
      "purple" => "45",
      "cyan" => "46",
      "gray" => "47",
      "dark gray" => "100",
      "light red" => "101",
      "light green" => "102",
      "yellow" => "103",
      "light blue" => "104",
      "light purple" => "105",
      "light cyan" => "106",
      "white" => "107"
    }

    color_code = colors[color]
    bgColor_code = bgColors[bgColor]
    return "\033[#{bgColor_code};#{color_code}m#{text}\033[0m"

end
