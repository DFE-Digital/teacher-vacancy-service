##
# Represents events occurring within the application that we are interested in tracking.
#
# At a minimum, an event has a type and a timestamp at which it occurred. It may also have optional
# metadata that describes what occurred in more detail. Events are asynchronously sent to our data
# warehouse using a background job. An instance of `Event` can trigger an arbitrary number of
# events (to allow for potentially expensive computation on initialization of subclasses).
class Event
  TABLE_NAME = "events".freeze

  ##
  # Asynchronously sends an event and its metadata to the data warehouse
  #
  # @param [Symbol, String] event_type The type of event (e.g. `:page_visited`) to trigger
  # @param [Hash{Symbol => Object}] data An optional hash of data to include with the event
  #   (Important: if present, values will be coerced into Strings)
  def trigger(event_type, data = {})
    data = base_data.merge(
      type: event_type,
      occurred_at: occurred_at(data),
      data: data.map { |key, value| { key: key.to_s, value: formatted_value(value) } },
    )
    SendEventToDataWarehouseJob.perform_later(TABLE_NAME, data)
  rescue StandardError => e
    Rollbar.error(e)
  end

  private

  ##
  # Data to be included with any event (to be overridden as appropriate in subclasses)
  def base_data
    {}
  end

  ##
  # For json objects or hashes passed to Event#trigger as values in the `data` param, such as
  # Subscription#search_criteria or Feedback#search_criteria, we should format these as json for BigQuery,
  # rather than strings, for easier data manipulation by Performance Analysis.
  # Arrays, such as job alert Feedbacks with a vacancy_ids attribute, should remain as arrays.
  # @param [Object] value Any value in the data passed to the event.
  def formatted_value(value)
    return value if value.is_a?(Array)

    value.respond_to?(:keys) ? value.to_json : value&.to_s
  end

  ##
  # When converting existing records into events, set `occurred_at` to the time the record was created, if the
  # record's `created_at` value is passed to Event#trigger in the `data` param.
  # @param [Hash{Symbol => Object}] data Any data included with the event, which, in the case of converting
  # existing records into events, will include attributes from the existing record being converted.
  def occurred_at(data)
    time = if data[:created_at].present?
             data[:created_at]
           else
             Time.now.utc
           end
    time.iso8601(6)
  end
end
