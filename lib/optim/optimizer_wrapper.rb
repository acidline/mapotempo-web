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
require 'rest_client'

class OptimizerWrapper

  attr_accessor :cache, :url, :api_key

  def initialize(cache, url, api_key)
    @cache, @url, @api_key = cache, url, api_key
  end

  def optimize(matrix, dimension, services, rests, optimize_time, soft_upper_bound, cluster_threshold)
    key = Digest::MD5.hexdigest(Marshal.dump([matrix, dimension, services, rests, optimize_time, soft_upper_bound, cluster_threshold]))

    result = @cache.read(key)
    if !result
      vrp = {
        matrices: {
          time: matrix.select{ |row| row.select(&:first) },
          distance: matrix.select{ |row| row.select(&:last) }
        },
        points: matrix.size.times.collect{ |i| {
          id: "p#{i}",
          matrix_index: i,
        }},
        services: services.each_with_index.collect{ |service, index| {
          id: "s#{index + 1}",
          point_id: "p#{index + 1}",
          timewindows: [{
            start: service[:start],
            end: service[:end],
          }],
          duration: service[:duration]
        }},
        rests: rests.each_with_index.collect{ |rest, index| {
          id: "r#{index}",
           timewindows: [{
            start: rest[:start],
            end: rest[:end]
          }],
          duration: rest[:duration]
        }},
        vehicles: [{
          id: 'v0',
          start_point_id: 'p0', ############################# TODO detect has start
          end_point_id: "p#{matrix.size - 1}", ################################ TODO detect has stop
          cost_fixed: 0,
          cost_distance_multiplicator: dimension == 'distance' ? 1 : 0,
          cost_time_multiplicator: dimension == 'time' ? 1 : 0,
          cost_waiting_time_multiplicator: dimension == 'time' ? 1 : 0,
          cost_late_multiplicator: dimension == 'time' ? soft_upper_bound : 0,
#          rests: rests.each_with_index.collect{ |rest, index| "r#{index}" }
        }],
        resolution: {
          preprocessing_cluster_threshold: cluster_threshold,
          preporcessing_prefer_short_segment: true,
          resolution_duration: optimize_time
         }
      }

      resource_vrp = RestClient::Resource.new(@url + '/vrp/submit.json')
      json = resource_vrp.post({api_key: @api_key, vrp: vrp}.to_json, content_type: :json, accept: :json)

      result = nil
      while json
        result = JSON.parse(json)
        if result.key?('solution')
          @cache.write(key, json && String.new(json)) # String.new workaround waiting for RestClient 2.0
          break
        elsif result.key?('job')
          sleep(2)
          job_id = result['job']['id']
          json = RestClient.get(@url + "/vrp/job/#{job_id}.json", params: {api_key: @api_key})
        else
          raise ##############################" TODO
        end
      end

      result['solution']['routes'][0]['activities'].collect{ |activitie|
        activitie['service_id'][1..-1].to_i - 1
      }
    end
  end
end