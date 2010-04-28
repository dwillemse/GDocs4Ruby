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
  #The Document class represents a Google Word Document.  Also check out BaseObject, the superclass of Document.
  #=Usage
  #All usages assume you've already authenticated with the service, and have a service object called
  #@service.  
  #1. Create a new Document
  #    doc = Document.new(@service)
  #    doc.title = 'Test Document'
  #    doc.content = '<h1>Test Content HTML</h1>'
  #    doc.content_type = 'html'
  #    doc.save
  #
  #2. Deleting a Document
  #    doc = Document.find(@service, {:id => @doc_id})
  #    doc.delete
  #
  #3. Finding an existing Document by id
  #    doc = Document.find(@service, {:id => @doc_id})
  #
  #4. Full Text Query
  #    doc = Document.find(@service, 'content text')
  #
  #   or
  #
  #    doc = Document.find(@service, {:query => 'content text'})
  #
  #5. Finding an Existing Document by Title
  #    doc = Document.find(@service, nil, {'title' => 'Test Document'})
  #
  #6. Updating a Document with Content from a Local File
  #    doc = Document.find(@service, {:id => @doc_id})
  #    doc.title = 'New Title'
  #    doc.local_file = '/path/to/some/file'
  #    doc.save
  #
  #7. Retrieving an Export
  #    doc = Document.find(@service, {:id => @doc_id})
  #    doc.download_to_file('pdf', '/path/to/save/location.pdf')
  
  class Document < BaseObject
    DOCUMENT_XML = '<?xml version="1.0" encoding="UTF-8"?>
<atom:entry xmlns:atom="http://www.w3.org/2005/Atom">
  <atom:category scheme="http://schemas.google.com/g/2005#kind"
      term="http://schemas.google.com/docs/2007#document" label="document"/>
  <atom:title>example document</atom:title>
</atom:entry>'
    DOWNLOAD_TYPES = ['doc', 'html', 'odt', 'pdf', 'png', 'rtf', 'txt', 'zip']
    EXPORT_URI = 'https://docs.google.com/feeds/download/documents/Export'
    
    #Creates a new Document instance.  Requires a valid Service object.
    def initialize(service, attributes = {})
      super(service, attributes)
      @xml = DOCUMENT_XML
    end
    
    #Retrieves an export of the Document.  The parameter +type+ must be one of the DOWNLOAD_TYPES.
    def get_content(type)
      if !@exists
        raise DocumentDoesntExist
      end
      if not DOWNLOAD_TYPES.include? type
        raise ArgumentError
      end
      ret = service.send_request(GData4Ruby::Request.new(:get, EXPORT_URI, nil, nil, {"docId" => @id,"exportFormat" => type}))
      ret.body
    end
    
    #Helper function limit queries to Documents.  See BaseObject#find for syntax.  Type is not required and assumed to be 'document'.
    def self.find(service, query, args = {})
      super(service, query, 'document', args)
    end
    
    #Downloads the export retrieved through get_content to a specified local file.  Parameters are:
    #*type*:: must be a valid type enumerated in DOWNLOAD_TYPES
    #*location*:: a valid file location for the local system
    def download_to_file(type, location)
      File.open(location, 'wb+') {|f| f.write(get_content(type)) }
    end
  end
end