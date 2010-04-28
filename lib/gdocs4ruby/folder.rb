module GDocs4Ruby
  class Folder < BaseObject
      FOLDER_XML = '<?xml version="1.0" encoding="UTF-8"?>
<atom:entry xmlns:atom="http://www.w3.org/2005/Atom">
  <atom:category scheme="http://schemas.google.com/g/2005#kind"
      term="http://schemas.google.com/docs/2007#folder" label="folder"/>
  <atom:title></atom:title>
</atom:entry>'

    #Returns true if the calendar exists on the Google Calendar system (i.e. was 
    #loaded or has been saved).  Otherwise returns false.
    
  
    def initialize(service, attributes = {})
      super(service, attributes)
      @xml = FOLDER_XML
    end

    public
    #Loads the Calendar with returned data from Google Calendar feed.  Returns true if successful.
    def load(string)
      super(string)
      xml = REXML::Document.new(string)
      xml.root.elements.each(){}.map do |ele|
#        case ele.name
#          
#        end
      end
      
      @folder_feed = @id
      return true
    end
    
    def folders
      ret = service.send_request(GData4Ruby::Request.new(:get, @content_uri+"/-/folder?showfolders=true"))
      folders = []
      REXML::Document.new(ret.body).root.elements.each("entry"){}.map do |entry|
        entry = GData4Ruby::Utils::add_namespaces(entry)
        folder = Folder.new(service)
        puts entry.to_s if service.debug
        folder.load("<?xml version='1.0' encoding='UTF-8'?>#{entry.to_s}")
        folders << folder
      end
      return folders
    end
    
    def files
      return nil if @content_uri == nil
      contents = []
      ret = @service.send_request(GData4Ruby::Request.new(:get, @content_uri))
      xml = REXML::Document.new(ret.body)
      xml.root.elements.each('entry'){}.map do |ele|
        ele = GData4Ruby::Utils::add_namespaces(ele)
        obj = BaseObject.new(@service)
        obj.load(ele.to_s)
        case obj.type
          when 'document'
            doc = Document.new(@service)
          when 'spreadsheet'
            doc = Spreadsheet.new(@service)
          when 'presentation'
            doc = Presentation.new(service)
        end
        doc.load(ele.to_s)
        contents << doc
      end
      return contents
    end
    
    def self.find(service, query, args = {})      
      raise ArgumentError if not query.is_a? Hash and not query.is_a? String
      ret = query.is_a?(String) ? [] : nil
      service.folders.each do |f|
        if (query.is_a? Hash and ((query[:id] and f.id == query[:id]) or (query[:query] and f.title.include? query[:query])))
          return f
        end
        if (query.is_a? String and f.title.include? query)
          ret << f
        end
      end
      return ret
    end
    
    def parent
      return nil if @parent_uri == nil
      ret = @service.send_request(GData4Ruby::Request.new(:get, @parent_uri))
      folder = nil
      puts ret.body if @service.debug
      folder = Folder.new(@service)
      folder.load(ret.body)
      return folder
    end
    
    def parent=newParent
      if newParent.is_a? Folder
        @parent_link = newParent.id
      end
    end
  end
end