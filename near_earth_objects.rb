require 'faraday'
require 'figaro'
require 'pry'
# Load ENV vars via Figaro
Figaro.application = Figaro::Application.new(environment: 'production', path: File.expand_path('../config/application.yml', __FILE__))
Figaro.load

class NearEarthObjects
  def self.find_neos_by_date(date)
    total_number_of_astroids = parsed_asteroids_data(asteroids_list_data(date), date).count

    {
      astroid_list: formatted_asteroid_data(parsed_asteroids_data(asteroids_list_data(date), date)),
      biggest_astroid: largest_astroid_diameter(parsed_asteroids_data(asteroids_list_data(date), date)),
      total_number_of_astroids: total_number_of_astroids
    }
  end

  def self.conn(date)
    Faraday.new(
      url: 'https://api.nasa.gov',
      params: { start_date: date, api_key: ENV['nasa_api_key']}
    )
  end

  def self.asteroids_list_data(date)
    conn(date).get('/neo/rest/v1/feed')
  end

  def self.largest_astroid_diameter(data)
    data.map do |astroid|
      astroid[:estimated_diameter][:feet][:estimated_diameter_max].to_i
    end.max { |a,b| a<=> b}
  end

  def self.parsed_asteroids_data(asteroids, date)
    JSON.parse(asteroids.body, symbolize_names: true)[:near_earth_objects][:"#{date}"]
  end

  def self.formatted_asteroid_data(list_data)
    list_data.map do |astroid|
      {
        name: astroid[:name],
        diameter: "#{astroid[:estimated_diameter][:feet][:estimated_diameter_max].to_i} ft",
        miss_distance: "#{astroid[:close_approach_data][0][:miss_distance][:miles].to_i} miles"
      }
    end
  end
end
