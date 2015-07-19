require 'spec_helper'
require_relative '../scraper_main'
require 'open-uri'

describe ScraperMain do
  it "can download the CSV files" do
    VCR.turned_off do
      WebMock.allow_net_connect!
      Net::HTTP.start(ScraperMain::CSV_HOST, 80) {|http| expect(http.head(ScraperMain::MLA_PATH).code).to eq "200" }
      Net::HTTP.start(ScraperMain::CSV_HOST, 80) {|http| expect(http.head(ScraperMain::MLC_PATH).code).to eq "200" }
    end
  end

  describe "#scrape", :vcr do
    context 'MLA' do
      it "scrapes details correctly" do
        records = subject.scrape ScraperMain::MLA_URL
        mill_park = records["d'ambrosio-mill park"]
        expect(mill_park.to_h).to eq MILL_PARK_RECORD
      end

      it "scrapes the right number of members" do
        records = subject.scrape ScraperMain::MLA_URL
        expect(records.count).to eq 88
      end
    end

    context 'MLC' do
      it "scrapes details correctly" do
        records = subject.scrape ScraperMain::MLC_URL
        finn_record = records["finn-western metropolitan"]
        expect(finn_record.to_h).to eq FINN_RECORD
      end

      it "scrapes the right number of members" do
        records = subject.scrape ScraperMain::MLC_URL
        expect(records.count).to eq 40
      end
    end
  end

  describe "#main", :vcr do
    before(:each) do
      ScraperWiki.config = { db: 'data.test', default_table_name: 'data' }
      ScraperWiki::sqliteexecute("drop table if exists data")
    end
    
    it "should merge members into one list" do
        subject.main
        south_west_coast = ScraperWiki::select('* FROM data WHERE electorate = "South-West Coast"')
        expect(south_west_coast.first).to eq(SOUTH_WEST_COAST_RECORD)
        expect(ScraperWiki::select('* FROM data').count).to eq(40+88)
    end
  end

  SOUTH_WEST_COAST_RECORD = {"type"=>"mp", "surname"=>"Napthine", "first_name"=>"Hon", "email"=>"denis.napthine@parliament.vic.gov.au", "office_address"=>"94 Liebig Street", "office_suburb"=>"Warrnambool", "office_postcode"=>"3280", "office_state"=>"VIC", "office_fax"=>"(03) 5562 6145", "office_phone"=>"(03) 5562 8230", "party"=>"Liberal Party", "electorate"=>"South-West Coast", "websites"=>"http://www.denisnapthine.com.au, http://www.facebook.com/DenisNapthine"}

  MILL_PARK_RECORD = {"type"=>"mp", "surname"=>"D'Ambrosio", "first_name"=>"Liliana", "email"=>"lily.d'ambrosio@parliament.vic.gov.au", "office_address"=>"6 May Road", "office_suburb"=>"Lalor", "office_postcode"=>"3075", "office_state"=>"VIC", "office_fax"=>"(03) 9464 1650", "office_phone"=>"(03) 9465 9033", "party"=>"Australian Labor Party", "electorate"=>"Mill Park", "websites"=>"http://twitter.com/LilyDAmbrosioMP"}

  FINN_RECORD = {"type"=>"senator", "surname"=>"Finn", "first_name"=>"Bernard", "email"=>"bernie.finn@parliament.vic.gov.au", "office_address"=>"Suite 1, 254 Ballarat Road", "office_suburb"=>"Braybrook", "office_postcode"=>"3019", "office_state"=>"VIC", "office_fax"=>"(03) 9317 5911", "office_phone"=>"(03) 9317 5900", "party"=>"Liberal Party", "electorate"=>"Western Metropolitan", "websites"=>""}
end

