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
require 'gdata4ruby/gdata_object'
require 'gdata4ruby/acl/access_rule'

module GDocs4Ruby
  
  #The base object class that includes all major methods for interacting with Google Documents API.
  #=Usage
  #All usages assume you've already authenticated with the service, and have a service object called
  #@service.  
  #*Note*: You probably don't want to instantiate a BaseObject directly, but rather use any of the subclasses
  #Document, Spreadsheet, and Presentation
  #1. Create a new Document
  #    doc = BaseObject.new(@service)
  #    doc.title = 'Test Document'
  #    doc.content = '<h1>Test Content HTML</h1>'
  #    doc.content_type = 'html'
  #    doc.save
  #
  #2. Deleting a Document
  #    doc = BaseObject.find(@service, {:id => @doc_id})
  #    doc.delete
  #
  #3. Finding an existing Document by id
  #    doc = BaseObject.find(@service, {:id => @doc_id})
  #
  #4. Full Text Query
  #    doc = BaseObject.find(@service, 'content text')
  #
  #   or
  #
  #    doc = BaseObject.find(@service, {:query => 'content text'})
  #
  #5. Finding an Existing Document by Title
  #    doc = BaseObject.find(@service, nil, 'any', {'title' => 'Test Document'})
  #
  #6. Updating a Document with Content from a Local File
  #    doc = BaseObject.find(@service, {:id => @doc_id})
  #    doc.title = 'New Title'
  #    doc.local_file = '/path/to/some/file'
  #    doc.save
  
  class BaseObject < GData4Ruby::GDataObject
    ENTRY_XML = '<atom:entry xmlns:atom="http://www.w3.org/2005/Atom">
  <atom:title></atom:title>
</atom:entry>'
    BOUNDARY = 'GDOCS4RUBY_BOUNDARY'
    UPLOAD_TYPES = {'' => 'text/txt',
                :csv => 'text/csv', 
                :tsv => 'text/tab-separated-values', 
                :tab => 'text/tab-separated-values',
                :html => 'text/html',
                :htm => 'text/html',
                :doc => 'application/msword',
                :docx => 'application/vnd.openxmlformats-officedocument.wordprocessingml.document',
                :ods => 'application/x-vnd.oasis.opendocument.spreadsheet',
                :odt => 'application/vnd.oasis.opendocument.text',
                :rtf => 'application/rtf',
                :sxw => 'application/vnd.sun.xml.writer',
                :txt => 'text/plain',
                :xls => 'application/vnd.ms-excel',
                :xlsx => 'application/vnd.openxmlformats-officedocument.spreadsheetml.sheet',
                :pdf => 'application/pdf',
                :ppt => 'application/vnd.ms-powerpoint',
                :pps => 'application/vnd.ms-powerpoint',
                :pptx => 'application/vnd.ms-powerpoint'}
                
    FEEDS = {:document => "https://docs.google.com/feeds/documents/private/full/",
             :folder => "http://docs.google.com/feeds/folders/private/full/",
             :spreadsheet => "https://docs.google.com/feeds/documents/private/full/",
             :presentation => "https://docs.google.com/feeds/documents/private/full/",
             :any => "https://docs.google.com/feeds/documents/private/full/"}
             
    QUERY_FEEDS = {:document => "https://docs.google.com/feeds/documents/private/full/-/document",
             :folder => "http://docs.google.com/feeds/folders/private/full/?showfolders=true",
             :spreadsheet => "https://docs.google.com/feeds/documents/private/full/-/spreadsheet",
             :presentation => "https://docs.google.com/feeds/documents/private/full/-/presentation",
             :any => "https://docs.google.com/feeds/documents/private/full/"}
             
    TYPES = ["document", "folder", "spreadsheet", "presentation", "any"]
    
    #The raw date the document was published
    attr_reader :published
    
    #The raw date the document was last updated
    attr_reader :updated
    
    #The author/owner name
    attr_reader :author_name
    
    #The author/owner email
    attr_reader :author_email
    
    #An array of folders this object belongs to
    attr_reader :folders
    
    #Quota bytes used by the document
    attr_reader :bytes_used
    
    #The type of the object, one of TYPES
    attr_reader :type
    
    #The uri for the html editor of the object (the web editor for documents)
    attr_reader :html_uri
    
    #The content uri for exporting the object content
    attr_reader :content_uri
    
    #Flag indicating whether the document has the 'viewed' category link.
    attr_reader :viewed
    
    #A local file to upload content from
    attr_accessor :local_file
    
    #Creates a new BaseObject instance.  Requires a valid GData4Ruby::Service object.
    def initialize(service, attributes = {})
      super(service, attributes)
      @xml = ENTRY_XML
      @folders = []
      @content_uri = nil
      @edit_content_uri = nil
      @viewed = false
      @content = @content_type = nil
    end
    
    public
    #Loads a string containing an XML <entry> from a Google API feed.
    def load(string)
      super(string)
      @folders = []
      xml = REXML::Document.new(string)
      xml.root.elements.each(){}.map do |ele|
        @etag = xml.root.attributes['etag'] if xml.root.attributes['etag']
        case ele.name
          when 'published'
            @published = ele.text
          when 'updated'
            @updated = ele.text
          when 'content'
            @content_uri = ele.attributes['src']
          when 'link'
            case ele.attributes['rel']
              when 'edit-media'
                @edit_content_uri = ele.attributes['href']
              when 'alternate'
                @html_uri = ele.attributes['href']
            end
          when 'author'
            ele.elements.each('name'){}.map {|e| @author_name = e.text}
            ele.elements.each('email'){}.map {|e| @author_email = e.text}
          when 'quotaBytesUsed'
            @bytes_used = ele.text
        end
      end
      @categories.each do |cat|
        @folders << cat[:label] if cat[:scheme] and cat[:scheme].include? "folders"
        @viewed = true if cat[:label] and cat[:label] == 'viewed'
        @type = cat[:label] if cat[:scheme] and cat[:scheme] == 'http://schemas.google.com/g/2005#kind'
      end
      return xml.root
    end
    
    #Sets content to save to the document.  Content must be formatted as one of the types in UPLOAD_TYPES.
    def content=(value)
      @content = value
    end
    
    #Sets the content_type stored in content. content_type must be one of the keys in UPLOAD_TYPES.
    def content_type=(value)
      @content_type = value
    end
    
    #Saves or creates the object depending on whether it exists or not.
    def save
      if @exists
        if (not @local_file.nil? and @local_file.is_a? String) or @content
          @include_etag = false
          if @local_file
            ret = service.send_request(GData4Ruby::Request.new(:put, @edit_content_uri, create_multipart_message([{:type => 'application/atom+xml', :content => to_xml()}, {:type => UPLOAD_TYPES[File.extname(@local_file).gsub(".", "").to_sym], :content => get_file(@local_file).read}]), {'Content-Type' => "multipart/related; boundary=#{BOUNDARY}", 'Content-Length' => File.size(@local_file).to_s, 'Slug' => File.basename(@local_file), 'If-Match' => "*"}))
          elsif @content
            ret = service.send_request(GData4Ruby::Request.new(:put, @edit_content_uri, create_multipart_message([{:type => 'application/atom+xml', :content => to_xml()}, {:type => UPLOAD_TYPES[@content_type.to_sym], :content => @content}]), {'Content-Type' => "multipart/related; boundary=#{BOUNDARY}", 'Content-Length' => @content.size.to_s, 'Slug' => @title, 'If-Match' => "*"}))
          end
        else
          ret = service.send_request(GData4Ruby::Request.new(:put, @edit_uri, to_xml()))
        end
        if not load(ret.read_body)
          raise SaveFailed
        end
        return true
      else
        return create
      end
    end
          
    #Retrieves an array of GData4Ruby::AccessRules representing the access rules for the object, as contained in the Google ACL.
    def access_rules
      rules = []
      ret = service.send_request(GData4Ruby::Request.new(:get, @acl_uri))
      xml = REXML::Document.new(ret.read_body).root
      xml.elements.each("entry") do |e|
        ele = GData4Ruby::Utils::add_namespaces(e)
        rule = GData4Ruby::ACL::AccessRule.new(service, self)
        puts ele.to_s if service.debug
        rule.load(ele.to_s)
        rules << rule
      end
      rules
    end
    
    #Adds a new access rule for the object.  Parameters are:
    #*user*::  the user (email address) to add permissions for
    #*role*::  can be one of 'viewer' or 'writer' depending on whether the user should be able to edit or read only.
    def add_access_rule(user, role)
      a = GData4Ruby::ACL::AccessRule.new(service, self)
      a.user = user
      a.role = role
      a.save
    end
    
# Waiting for V3 to graduate    
#    def set_publicly_writable(value)
#      if value
#        a = GData4Ruby::ACL::AccessRule.new(service, self)
#        a.role = 'writer'
#        a.save
#      else
#        remove_access_rule('default', 'writer')
#      end
#    end
    
# Waiting for V3 to graduate 
#    def set_publicly_readable(value)
#      if value
#        a = GData4Ruby::ACL::AccessRule.new(service, self)
#        a.role = 'reader'
#        a.save
#      else
#        remove_access_rule('default', 'reader')
#      end
#    end
    
    #Updates an existing access rule for the object.  Parameters are:
    #*user*::  the user (email address) to update permissions
    #*role*::  can be one of 'viewer' or 'writer' depending on whether the user should be able to edit or read only.
    def update_access_rule(user, role)
      a = GData4Ruby::ACL::AccessRule.find(service, self, {:user => user})
      if a
        a.role = role
        if a.save
          return true
        end
      end
      return false
    end
    
    #Removes an access rule for the specified user.  Parameter should be a valid user Id (email address).
    def remove_access_rule(user)
      a = GData4Ruby::ACL::AccessRule.find(service, self, {:user => user})
      if a
        if a.delete
          return true
        end
      end
      return false
    end
    
    #Creates a new object instance on the Google server if the object doesn't already exist.
    def create
      ret = if (not @local_file.nil? and @local_file.is_a? String) or @content
        if @local_file
          service.send_request(GData4Ruby::Request.new(:post, DOCUMENT_LIST_FEED, create_multipart_message([{:type => 'application/atom+xml', :content => to_xml()}, {:type => UPLOAD_TYPES[File.extname(@local_file).gsub(".", "").to_sym], :content => get_file(@local_file).read}]), {'Content-Type' => "multipart/related; boundary=#{BOUNDARY}", 'Content-Length' => File.size(@local_file).to_s, 'Slug' => File.basename(@local_file)}))
        elsif @content
          service.send_request(GData4Ruby::Request.new(:post, DOCUMENT_LIST_FEED, create_multipart_message([{:type => 'application/atom+xml', :content => to_xml()}, {:type => UPLOAD_TYPES[@content_type.to_sym], :content => @content}]), {'Content-Type' => "multipart/related; boundary=#{BOUNDARY}", 'Content-Length' => @content.size.to_s, 'Slug' => @title}))
        end      
      else
        service.send_request(GData4Ruby::Request.new(:post, DOCUMENT_LIST_FEED, to_xml()))
      end
      if not load(ret.read_body)
        raise SaveFailed
      end
      return ret
    end
    
    #Returns a simple iframe containing the html_uri link for the document.  
    #
    #*Note:* you must either be logged in to Google
    #as the owner of the document for this to work, or have appropriate read/write permissions set up on the document.
    def to_iframe(options = {})
      width = options[:width] || '800'
      height = options[:height] || '500'
      return "<iframe height='#{height}' width='#{width}' src='#{@html_uri}'></iframe>"
    end
    
    #Saves arbitrary content to the object.  Parameters must be:
    #*content*:: the content to upload.  Content should be formatted as one of the UPLOAD_TYPES.
    #*type*:: an optional paramter specifying the type, if not HTML.  This value must be a mime-type enumerated in UPLOAD_TYPES.
    def put_content(content, type = 'text/html')
      ret = service.send_request(GData4Ruby::Request.new(:put, @edit_content_uri, content, {'Content-Type' => type, 
                                                 'Content-Length' => content.length.to_s,
                                                 'If-Match' => "*"}))
      load(ret.body)
    end
    
    #Finds a BaseObject based on a text query or by an id.  Parameters are:
    #*service*::  A valid Service object to search.
    #*query*:: either a string containing a text query to search by, or a hash containing an +id+ key with an associated id to find, or a +query+ key containint a text query to search for.
    #*type*:: used to limit results to a specific document type, as list in TYPES.
    #*args*:: a hash containing optional additional query paramters to use.  See http://code.google.com/apis/gdata/docs/2.0/reference.html#Queries for a full list of possible values.  Example: 
    # {'max-results' => '100'}
    #If an ID is specified, a single instance of the document is returned if found, otherwise false.
    #If a query term is specified, and array of matching results is returned, or an empty array if nothing
    #was found.
    def self.find(service, query, type = 'any', args = {})      
      raise ArgumentError, 'query must be a hash or string' if not query.is_a? Hash and not query.is_a? String
      raise ArgumentError, "type must be one of #{TYPES.join(" ")}" if not TYPES.include? type
      if query.is_a? Hash and query[:id]
        id = query[:id]
        puts "id passed, finding event by id" if service.debug
        puts "id = "+id if service.debug
        d = service.send_request(GData4Ruby::Request.new(:get, FEEDS[type.to_sym]+id, {"If-Not-Match" => "*"}))
        puts d.inspect if service.debug
        if d
          return get_instance(service, d)
        end
      else
        results = []
        term = query.is_a?(Hash) ? CGI::escape(query[:query]) : CGI::escape(query)
        args["q"] = term if term and term != ''
        ret = service.send_request(GData4Ruby::Request.new(:get, QUERY_FEEDS[type.to_sym], nil, nil, args))
        xml = REXML::Document.new(ret.body).root
        xml.elements.each("entry") do |e|
          results << get_instance(service, e)
        end
        return results
      end
      return false
    end
    
    #Adds the object to the specified folder.  The parameter must be a valid Folder object.
    def add_to_folder(folder)
      raise ArgumentError, 'folder must be a GDocs4Ruby::Folder' if not folder.is_a? Folder
      @service.send_request(GData4Ruby::Request.new(:post, folder.content_uri, to_xml))
    end
    
    #Removes the object from the specified folder.  The parameter must be a valid Folder object.
    def remove_from_folder(folder)
      raise ArgumentError, 'folder must be a GDocs4Ruby::Folder' if not folder.is_a? Folder
      @service.send_request(GData4Ruby::Request.new(:delete, folder.content_uri+"/"+CGI::escape(id), nil, {"If-Match" => "*"}))
    end
    
    private
    def self.get_instance(service, d)
      if d.is_a? Net::HTTPOK
        xml = REXML::Document.new(d.read_body).root
        if xml.name == 'feed'
          xml = xml.elements.each("entry"){}[0]
        end
      else
        xml = d
      end
      ele = GData4Ruby::Utils::add_namespaces(xml)
      obj = BaseObject.new(service)
      obj.load(ele.to_s)
      case obj.type
        when 'document'
          doc = Document.new(service)
        when 'spreadsheet'
          doc = Spreadsheet.new(service)
        when 'folder'
          doc = Folder.new(service)
        when 'presentation'
          doc = Presentation.new(service)
      end
      doc.load(ele.to_s)
      doc
    end
    
    def get_file(filename)
      file = File.open(filename, "rb")
      raise FileNotFoundError if not file
      return file
    end
    
    def create_multipart_message(parts)
      ret = ''
      parts.each do |p|
        ret += "--#{BOUNDARY}\nContent-Type: #{p[:type]}\n\n#{p[:content]}\n\n"
      end
      ret += "--#{BOUNDARY}--\n"
    end
  end
end