require 'gdata4ruby/gdata_object'
require 'gdata4ruby/acl/access_rule'

module GDocs4Ruby
  class BaseObject < GData4Ruby::GDataObject
    ENTRY_XML = '<atom:entry xmlns:atom="http://www.w3.org/2005/Atom">
  <atom:title></atom:title>
</atom:entry>'
    BOUNDARY = 'GCAL4RUBY_BOUNDARY'
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
    
    attr_reader :published
    
    attr_reader :updated
    
    attr_reader :author_name
    
    attr_reader :author_email
    
    attr_reader :folders
    
    attr_reader :bytes_used
    
    attr_reader :type
    
    attr_reader :html_uri
    
    attr_reader :content_uri
    
    attr_reader :viewed
    
    attr_accessor :content
    
    attr_accessor :content_type
    
    attr_accessor :local_file
    
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
    
    def remove_access_rule(user)
      a = GData4Ruby::ACL::AccessRule.find(service, self, {:user => user})
      if a
        if a.delete
          return true
        end
      end
      return false
    end
    
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
    
    def to_xml
      super
    end
    
    def to_iframe(options = {})
      width = options[:width] || '800'
      height = options[:height] || '500'
      return "<iframe height='#{height}' width='#{width}' src='http://docs.google.com/Doc?docid=#{@id}'></iframe>"
    end
    
    def put_content(content, type = 'text/html')
      ret = service.send_request(GData4Ruby::Request.new(:put, @edit_content_uri, content, {'Content-Type' => type, 
                                                 'Content-Length' => content.length.to_s,
                                                 'If-Match' => "*"}))
      load(ret.body)
    end
    
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
    
    def add_to_folder(folder)
      raise ArgumentError, 'folder must be a GDocs4Ruby::Folder' if not folder.is_a? Folder
      @service.send_request(GData4Ruby::Request.new(:post, folder.content_uri, to_xml))
    end
    
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