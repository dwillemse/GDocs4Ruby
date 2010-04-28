module GDocs4Ruby
  class Document < BaseObject
    DOCUMENT_XML = '<?xml version="1.0" encoding="UTF-8"?>
<atom:entry xmlns:atom="http://www.w3.org/2005/Atom">
  <atom:category scheme="http://schemas.google.com/g/2005#kind"
      term="http://schemas.google.com/docs/2007#document" label="document"/>
  <atom:title>example document</atom:title>
</atom:entry>'
    DOWNLOAD_TYPES = ['doc', 'html', 'odt', 'pdf', 'png', 'rtf', 'txt', 'zip']
    EXPORT_URI = 'https://docs.google.com/feeds/download/documents/Export'
    
    def initialize(service, attributes = {})
      super(service, attributes)
      @xml = DOCUMENT_XML
    end
    
    def to_xml
      xml = REXML::Document.new(super)
      xml.root.elements.each(){}.map do |ele|
        case ele.name
        when "title"
          ele.text = @title
        end
      end
      xml.to_s
    end
    
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
    
    def self.find(service, query, args = {})
      super(service, query, 'document', args)
    end
    
    def download_to_file(type, location)
      File.open(location, 'wb+') {|f| f.write(get_content(type)) }
    end
  end
end