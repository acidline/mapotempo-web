json.route_id route.id
(json.duration (route.start && route.end) ? '%i:%02i' % [(route.end - route.start) / 60 / 60, (route.end - route.start) / 60 % 60] : '0:00')
(json.hidden true) if route.hidden
(json.locked true) if route.locked
json.distance locale_distance(route.distance || 0, current_user.prefered_unit)
json.size route.stops.size
json.extract! route, :ref, :color, :size_active
(json.start l(route.start.utc, format: :hour_minute)) if route.start
(json.end l(route.end.utc, format: :hour_minute)) if route.end
json.color_fake route.color
json.last_sent_to route.last_sent_to if route.last_sent_to
json.last_sent_at_formatted l(route.last_sent_at) if route.last_sent_at
json.optimized_at_formatted l(route.optimized_at) if route.optimized_at
if !@planning.customer.enable_orders
  json.quantities route_quantities(route) do |units|
    json.quantity units[:quantity] if units[:quantity]
    json.unit_icon units[:unit_icon]
  end
end
if route.vehicle_usage
  json.contact_email route.vehicle_usage.vehicle.contact_email if route.vehicle_usage.vehicle.contact_email
  json.vehicle_usage_id route.vehicle_usage.id
  json.vehicle_id route.vehicle_usage.vehicle.id
  json.work_time '%i:%02i' % [(route.vehicle_usage.default_close - route.vehicle_usage.default_open) / 60 / 60, (route.vehicle_usage.default_close - route.vehicle_usage.default_open) / 60 % 60]
  # Devices
  (json.teksat true) if !route.vehicle_usage.vehicle.devices_linking.nil? && !route.vehicle_usage.vehicle.devices_linking[:teksat_id].blank? && route.planning.customer.teksat?
  (json.tomtom true) if !route.vehicle_usage.vehicle.devices_linking.nil? && !route.vehicle_usage.vehicle.devices_linking[:tomtom_id].blank? && route.planning.customer.tomtom?
  (json.orange true) if !route.vehicle_usage.vehicle.devices_linking.nil? && !route.vehicle_usage.vehicle.devices_linking[:orange_id].blank? && route.planning.customer.orange?
  (json.alyacom true) if route.planning.customer.alyacom?
  (json.masternaut true) if !route.vehicle_usage.vehicle.devices_linking.nil? && !route.vehicle_usage.vehicle.devices_linking[:masternaut_ref].blank? && route.planning.customer.masternaut?
  status_uniq = route.stops.map{ |stop|
      {
        code: stop.status.downcase,
        status: t("plannings.edit.stop_status.#{stop.status.downcase}", default: stop.status)
      } if stop.status
    }.uniq.compact
  json.status_all do
    # FIXME: to avoid refreshing select active stops, combined here with hardcoded status
    json.array! status_uniq | [:planned, :started, :finished, :rejected].map{ |status|
      {
        code: status.to_s.downcase,
        status: t("plannings.edit.stop_status.#{status.to_s}")
      }
    }
  end
  json.status_any status_uniq.size > 0 || (!route.vehicle_usage.vehicle.devices_linking.nil? && !route.vehicle_usage.vehicle.devices_linking[:tomtom_id].blank? && route.planning.customer.tomtom?)
end
number = 0
no_geolocalization = out_of_window = out_of_capacity = out_of_drive_time = no_path = false
json.store_start do
  json.extract! route.vehicle_usage.default_store_start, :id, :name, :street, :postalcode, :city, :country, :lat, :lng, :color, :icon, :icon_size
  (json.time l(route.start.utc, format: :hour_minute)) if route.start
  (json.geocoded true) if route.vehicle_usage.default_store_start.position?
  (json.error true) if !route.vehicle_usage.default_store_start.position?
end if route.vehicle_usage && route.vehicle_usage.default_store_start
(json.start_with_service l(display_start_time(route).utc, format: :hour_minute)) if display_start_time(route)
previous_with_pos = route.vehicle_usage && route.vehicle_usage.default_store_start.try(&:position?)
first_active_free = nil
route.stops.select{ |s| s.is_a?(StopVisit) }.sort_by{ |s| s.index || Float::INFINITY }.reverse_each{ |stop|
  if !stop.active
    first_active_free = stop
  else
    break
  end
}
json.stops route.vehicle_usage_id ? route.stops.sort_by{ |s| s.index || Float::INFINITY } : (route.stops.all?{ |s| s.name.to_i != 0 } ? route.stops.sort_by{ |s| s.name.to_i } : route.stops.sort_by{ |s| s.name.to_s.downcase }) do |stop|
  out_of_window |= stop.out_of_window
  out_of_capacity |= stop.out_of_capacity
  out_of_drive_time |= stop.out_of_drive_time
  no_geolocalization |= stop.is_a?(StopVisit) && !stop.position?
  no_path |= stop.position? && stop.active && route.vehicle_usage && !stop.trace && previous_with_pos
  (json.error true) if (stop.is_a?(StopVisit) && !stop.position?) || (stop.position? && stop.active && route.vehicle_usage && !stop.trace && previous_with_pos) || stop.out_of_window || stop.out_of_capacity || stop.out_of_drive_time
  json.stop_id stop.id
  json.extract! stop, :name, :street, :detail, :postalcode, :city, :country, :comment, :phone_number, :lat, :lng, :drive_time, :trace, :out_of_window, :out_of_capacity, :out_of_drive_time
  json.ref stop.ref if @planning.customer.enable_references
  json.open_close1 stop.open1 || stop.close1
  (json.open1 l(stop.open1.utc, format: :hour_minute)) if stop.open1
  (json.close1 l(stop.close1.utc, format: :hour_minute)) if stop.close1
  json.open_close2 stop.open2 || stop.close2
  (json.open2 l(stop.open2.utc, format: :hour_minute)) if stop.open2
  (json.close2 l(stop.close2.utc, format: :hour_minute)) if stop.close2
  (json.wait_time '%i:%02i' % [stop.wait_time / 60 / 60, stop.wait_time / 60 % 60]) if stop.wait_time && stop.wait_time > 60
  (json.geocoded true) if stop.position?
  (json.no_path true) if stop.position? && stop.active && route.vehicle_usage && !stop.trace && previous_with_pos
  (json.time l(stop.time.utc, format: :hour_minute)) if stop.time
  (json.active true) if stop.active
  (json.number number += 1) if route.vehicle_usage && stop.active
  (json.link_phone_number current_user.link_phone_number) if current_user.url_click2call
  json.distance (stop.distance || 0) / 1000
  if stop.is_a?(StopVisit)
    if first_active_free == true || first_active_free == stop || !route.vehicle_usage
      json.automatic_insert true
      first_active_free = true
    end
    json.visits true
    visit = stop.visit
    json.visit_id visit.id
    json.destination do
      json.destination_id visit.destination.id
      (json.color visit.color) if visit.color
      (json.icon visit.icon) if visit.icon
    end
    json.index_visit (visit.destination.visits.index(visit) + 1) if visit.destination.visits.size > 1
    tags = visit.destination.tags | visit.tags
    if !tags.empty?
      json.tags_present do
        json.tags do
          json.array! tags, :label
        end
      end
    end
    if @planning.customer.enable_orders
      order = stop.order
      if order
        json.orders order.products.collect(&:code).join(', ')
      end
    else
      json.quantities visit_quantities(visit, route.vehicle_usage && route.vehicle_usage.vehicle) do |quantity|
        json.quantity quantity[:quantity] if quantity[:quantity]
        json.unit_icon quantity[:unit_icon]
      end
    end
    if stop.status
      json.status t("plannings.edit.stop_status.#{stop.status.downcase}", default: stop.status)
      json.status_code stop.status.downcase
    end
    if stop.route.last_sent_to && stop.status && stop.eta
      (json.eta_formated l(stop.eta, format: :hour_minute)) if stop.eta
    end
  elsif stop.is_a?(StopRest)
    json.rest do
      json.rest true
      (json.store_id route.vehicle_usage.default_store_rest.id) if route.vehicle_usage.default_store_rest
      (json.geocoded true) if route.vehicle_usage.default_store_rest && route.vehicle_usage.default_store_rest.position?
      (json.error true) if route.vehicle_usage.default_store_rest && !route.vehicle_usage.default_store_rest.position?
    end
  end
  json.duration l(Time.at(stop.duration).utc, format: :hour_minute_second) if stop.duration > 0
  previous_with_pos = stop if stop.position?
end
json.store_stop do
  json.extract! route.vehicle_usage.default_store_stop, :id, :name, :street, :postalcode, :city, :country, :lat, :lng, :color, :icon, :icon_size
  (json.time l(route.end.utc, format: :hour_minute)) if route.end
  (json.geocoded true) if route.vehicle_usage.default_store_stop.position?
  (json.no_path true) if !route.distance.nil? && route.distance > 0 && route.vehicle_usage.default_store_stop.position? && !route.stop_trace
  (json.error true) if !route.vehicle_usage.default_store_stop.position? || (!route.distance.nil? && route.distance > 0 && route.vehicle_usage.default_store_stop.position? && !route.stop_trace)
  json.stop_trace route.stop_trace
  (json.error true) if route.stop_out_of_drive_time
  json.stop_out_of_drive_time route.stop_out_of_drive_time
  out_of_drive_time |= route.stop_out_of_drive_time
  json.stop_distance (route.stop_distance || 0) / 1000
  json.stop_drive_time route.stop_drive_time
end if route.vehicle_usage && route.vehicle_usage.default_store_stop
(json.end_without_service l(display_end_time(route).utc, format: :hour_minute)) if display_end_time(route)
(json.route_no_geolocalization no_geolocalization) if no_geolocalization
(json.route_out_of_window out_of_window) if out_of_window
(json.route_out_of_capacity out_of_capacity) if out_of_capacity
(json.route_out_of_drive_time out_of_drive_time) if out_of_drive_time
(json.route_no_path no_path) if no_path
(json.route_error true) if no_geolocalization || out_of_window || out_of_capacity || out_of_drive_time
