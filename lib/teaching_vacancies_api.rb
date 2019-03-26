module TeachingVacancies
  class API
    BASE_URL = 'https://teaching-vacancies.service.gov.uk/api/v1/'.freeze

    def jobs(limit: 10)
      response = HTTParty.get(api_url('jobs.json'))
      json = JSON.parse(response.body)
      json['data'].take(limit)
    rescue HTTParty::ResponseError => e
      Rails.logger.warn("Teaching Vacancies API response error: #{e.message}")
    end

    private

    def api_url(endpoint)
      BASE_URL + endpoint
    end
  end
end