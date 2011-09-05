require 'rest-client'
require 'nokogiri'
require 'sinatra'
require 'haml'

get '/' do
    haml :home
end

post '/my-buses' do
    redirect "/buses/#{params[:token]}"
end

get '/buses/:token' do |token|
    doc = Nokogiri::HTML(RestClient.get('http://accessible.countdown.tfl.gov.uk/myStops',
                                        {:cookies => {:UserToken => token}}))

    stops = doc.css('.myStopSection').map do |element|
        {
            name: element.css('.stopInfo').text[/\s*(.+)\r/, 1],
            stop_id: element.css('.stopInfo').attribute('id').value,
            stop_letter: element.css('.stopInfo').text[/\((\w+)\)/, 1],
            towards: element.xpath("div[contains(text(), 'towards')]").text.gsub('towards ', ''),
            buses: element.css('.results tbody tr').map do |row|
            {
                route: row.css('.resRoute').text.strip,
                direction: row.css('.resDir').text.strip,
                due: row.css('.resDue').text,
            }
            end
        }
    end

    haml :buses, :locals => {:stops => stops}
end
