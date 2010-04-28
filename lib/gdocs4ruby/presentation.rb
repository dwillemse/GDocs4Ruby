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
  #The Presentation class represents a Google Presentation.  Also check out Document and BaseObject, the superclass of Presentation.
  #=Usage
  #All usages assume you've already authenticated with the service, and have a service object called
  #@service.  
  #1. Create a new Presentation
  #    p = Presentation.new(@service)
  #    p.title = 'Test Presentation'
  #    p.local_file = '/path/to/some/spreadsheet.ppt'
  #    p.save
  #
  #2. Deleting a Presentation
  #    p = Presentation.find(@service, {:id => @doc_id})
  #    p.delete
  #
  #3. Finding an existing Presentation by id
  #    p = Presentation.find(@service, {:id => @doc_id})
  #
  #4. Full Text Query
  #    p = Presentation.find(@service, 'content text')
  #
  #   or
  #
  #    p = Presentation.find(@service, {:query => 'content text'})
  #
  #5. Finding an Existing Spreadsheet by Title
  #    p = Presentation.find(@service, nil, {'title' => 'Test Presentation'})
  #
  #6. Retrieving an Export
  #    p = Presentation.find(@service, {:id => @doc_id})
  #    p.download_to_file('pdf', '/path/to/save/location.pdf')
  
  class Presentation < Document
    DOCUMENT_XML = '<?xml version="1.0" encoding="UTF-8"?>
<atom:entry xmlns:atom="http://www.w3.org/2005/Atom">
  <atom:category scheme="http://schemas.google.com/g/2005#kind"
      term="http://schemas.google.com/docs/2007#spreadsheet" label="presentation"/>
  <atom:title></atom:title>
</atom:entry>'
    DOWNLOAD_TYPES = ['pdf', 'png', 'ppt', 'swf', 'txt']
    EXPORT_URI = 'http://docs.google.com/feeds/download/presentations/Export'
    
    #Helper function limit queries to Presentations.  See BaseObject::find for syntax.  Type is not required and assumed to be 'presentation'.
    def self.find(service, query, args = {})
      BaseObject::find(service, query, 'presentation', args)
    end
    
    #Creates a new Presentation instance.  Requires a valid Service object.
    def initialize(service, attributes = {})
      super(service, attributes)
      @xml = DOCUMENT_XML
    end
    
    #Retrieves an export of the Presentation.  The parameter +type+ must be one of the DOWNLOAD_TYPES
    def get_content(type)
      if !@exists
        raise DocumentDoesntExist
      end
      if not DOWNLOAD_TYPES.include? type
        raise ArgumentError
      end
      ret = service.send_request(GData4Ruby::Request.new(:get, EXPORT_URI, nil, nil, {"docID" => @id,"exportFormat" => type}))
      ret.body
    end
  end
end