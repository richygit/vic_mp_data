require 'fileutils'
require_relative 'csv_scraper'
require './logging'
require 'scraperwiki'
require 'csv'
require 'open-uri'
require_relative 'phone_helper'

class ScraperMain < Logging
  CSV_HOST = 'www.parliament.vic.gov.au'
  MLA_PATH = '/members/house/mla?format=csv'
  MLC_PATH = '/members/house/mlc?format=csv'
  MLA_URL = "http://#{CSV_HOST}#{MLA_PATH}"
  MLC_URL = "http://#{CSV_HOST}#{MLC_PATH}"

  def scrape(url)
    records = {}
    csv = CSV.read(open(url), :headers => :true)
    headers = csv.headers
    csv.each do |line|
      key, record = parse_record(line, headers)
      records[key] = record
    end
    records
  end

private

  def blank?(str)
    str == nil || str !~ /\S/ 
  end

  def parse_name(name)
    first_name = name.match(/\w+\s+([\w\-']+)/)[1]
    surname = name.match(/\s([\w\-']+$)/)[1]
    [first_name, surname]
  end

  def parse_office_address(address)
    address.scan(/(.*),\s*(.+),\s*(.+)$/).flatten
  end

  def parse_record(row, headers)
    first_name, surname = parse_name(row['Name'])
    record = {}
    record['type'] = row['House'] == 'MLA' ? 'mp' : 'senator'
    record['surname'] = surname
    record['first_name'] = first_name
    record['email'] = row['Email']
    office_address, office_suburb, office_state = parse_office_address(row['Electorate Office Address complete'])
    record['office_address'] = office_address
    record['office_suburb'] = office_suburb
    record['office_postcode'] = row['Electoral Office Postcode']
    record['office_state'] = office_state
    record['office_fax'] = row['Fax']
    record['office_phone'] = row['Phone']
    record['party'] = row['Party']
    record['electorate'] = row['Electorate']
    record['websites'] = row['WWW']
    key = "#{record['surname'].downcase}-#{record['electorate'].downcase}"
    [key, record]
  end

  def contact_address(row)
    address = row['CONTACT ADDRESS LINE1']
    address += ' ' + row['CONTACT ADDRESS LINE2'] if row['CONTACT ADDRESS LINE2']
    address += ' ' + row['CONTACT ADDRESS LINE3'] if row['CONTACT ADDRESS LINE3']
    address.strip
  end

  def main
    mla = scrape(MLA_URL)
    mlc = scrape(MLC_URL)

    csv_records.each do |key, record|
      @logger.info("### Saving #{record['first_name']} #{record['surname']}")
      puts("### Saving #{record['first_name']} #{record['surname']}")
      ScraperWiki::save(['surname', 'electorate'], record)
    end
  end
end
