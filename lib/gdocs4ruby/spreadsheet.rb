# Author:: Mike Reich (mike@seabourneconsulting.com)
# Copyright:: Copyright (C) 2010 Mike Reich
# License:: GPL v2
#--
# Licensed under the General Public License (GPL), Version 2.0 (the "License");
# you may not use this file except in compliance with the License.
# You may obtain a copy of the License at
#
#      http://www.gnu.org/licenses/old-licenses/gpl-2.0.txt
#
# Unless required by applicable law or agreed to in writing, software
# distributed under the License is distributed on an "AS IS" BASIS,
# WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
#
# Feel free to use and update, but be sure to contribute your
# code back to the project and attribute as required by the license.
#++
module GDocs4Ruby
  #The Spreadsheet class represents a Google Spreadsheet.  Also check out Document and BaseObject, the superclass of Spreadsheet.
  #=Usage
  #All usages assume you've already authenticated with the service, and have a service object called
  #@service.  
  #1. Create a new Spreadsheet
  #    s = Spreadsheet.new(@service)
  #    s.title = 'Test Spreadsheet'
  #    s.local_file = '/path/to/some/spreadsheet.xls'
  #    s.save
  #
  #2. Deleting a Spreadsheet
  #    s = Spreadsheet.find(@service, {:id => @doc_id})
  #    s.delete
  #
  #3. Finding an existing Spreadsheet by id
  #    s = Spreadsheet.find(@service, {:id => @doc_id})
  #
  #4. Full Text Query
  #    s = Spreadsheet.find(@service, 'content text')
  #
  #   or
  #
  #    s = Spreadsheet.find(@service, {:query => 'content text'})
  #
  #5. Finding an Existing Spreadsheet by Title
  #    s = Spreadsheet.find(@service, nil, {'title' => 'Test Spreadsheet'})
  #
  #6. Retrieving an Export
  #    s = Spreadsheet.find(@service, {:id => @doc_id})
  #    s.download_to_file('pdf', '/path/to/save/location.pdf')
  
  class Spreadsheet < Document
    DOCUMENT_XML = '<?xml version="1.0" encoding="UTF-8"?>
<atom:entry xmlns:atom="http://www.w3.org/2005/Atom">
  <atom:category scheme="http://schemas.google.com/g/2005#kind"
      term="http://schemas.google.com/docs/2007#spreadsheet" label="spreadsheet"/>
  <atom:title></atom:title>
</atom:entry>'
    DOWNLOAD_TYPES = ['xls', 'csv', 'pdf', 'ods', 'tsv', 'html']
    EXPORT_URI = 'http://spreadsheets.google.com/feeds/download/spreadsheets/Export'
    
    #Helper function limit queries to Spreadsheets.  See BaseObject::find for syntax.  Type is not required and assumed to be 'spreadsheet'.
    def self.find(service, query, args = {})
      BaseObject::find(service, query, 'spreadsheet', args)
    end
    
    #Creates a new Spreadsheet instance.  Requires a valid Service object.
    def initialize(service, attributes = {})
      super(service, attributes)
      @xml = DOCUMENT_XML
    end
    
    #Retrieves an export of the Spreadsheet.  The parameter +type+ must be one of the DOWNLOAD_TYPES.
    def get_content(type)
      if !@exists
        raise DocumentDoesntExist
      end
      if not DOWNLOAD_TYPES.include? type
        raise ArgumentError
      end
      service.reauthenticate('wise')
      ret = service.send_request(GData4Ruby::Request.new(:get, EXPORT_URI, nil, nil, {"key" => @id.gsub(/\w.*:/, ""),"exportFormat" => type}))
      service.reauthenticate()
      ret.body
    end
  end
end