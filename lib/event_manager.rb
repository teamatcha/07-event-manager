require 'csv'
require 'google/apis/civicinfo_v2'
require 'erb'
require 'date'

def clean_zipcode(zipcode)
  zipcode.to_s.rjust(5, '0')[0..4]
end

def legislators_by_zipcode(zip)
  civic_info = Google::Apis::CivicinfoV2::CivicInfoService.new
  civic_info.key = 'AIzaSyClRzDqDh5MsXwnCWi0kOiiBivP6JsSyBw'

  begin
    legislators = civic_info.representative_info_by_address(
      address: zip,
      levels: 'country',
      roles: ['legislatorUpperBody', 'legislatorLowerBody']
    ).officials
  rescue
    'You can find your representatives by visiting www.commoncause.org/take-action/find-elected-officials'
  end
end

def clean_phone_numbers(phone)
  phone = phone.gsub(/\W+/, "")
  if phone.length == 10
    phone
  elsif phone.length > 10 && phone[0] == '1'
    phone[1..-1]
  else
    "Bad number"
  end
end

def time_targeting(date)
  date.tally.max_by { |k, v| v }
end

def save_thank_you_letter(id, form_letter)
  Dir.mkdir('output') unless Dir.exists?('output')
  filename = "output/thanks_#{id}.html"
  File.open(filename, 'w') do |file|
    file.puts form_letter
  end
end

puts 'EventManager Initialized!'

contents = CSV.open('event_attendees.csv', headers: true, header_converters: :symbol)
template_letter = File.read('form_letter.erb')
erb_template = ERB.new template_letter
hours_array = []
day_array = []
hour_of_the_day = ""
day_of_the_week = ""

contents.each do |row|
  id = row[0]
  name = row[:first_name]

  zipcode = clean_zipcode(row[:zipcode])

  legislators = legislators_by_zipcode(zipcode)

  phone_number = clean_phone_numbers(row[:homephone])

  puts "#{name} -  #{phone_number}"

  registration_date = DateTime.strptime(row[:regdate], '%m/%d/%y %H:%M')

  hours_array << registration_date.hour
  day_array << registration_date.strftime('%A')

  hour_of_the_day = time_targeting(hours_array)
  day_of_the_week = time_targeting(day_array)

  form_letter = erb_template.result(binding)
  save_thank_you_letter(id, form_letter)
end

puts "Most frequented hours : #{hour_of_the_day[0]}h"
puts "Most frequented in the week : #{day_of_the_week[0]}"
