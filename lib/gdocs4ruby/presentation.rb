require 'gdocs4ruby/service'
require 'gdocs4ruby/folder'
require 'gdocs4ruby/base_object'
require 'gdocs4ruby/document'

module GDocs4Ruby
  class Presentation < Document
    DOCUMENT_XML = '<?xml version="1.0" encoding="UTF-8"?>
<atom:entry xmlns:atom="http://www.w3.org/2005/Atom">
  <atom:category scheme="http://schemas.google.com/g/2005#kind"
      term="http://schemas.google.com/docs/2007#spreadsheet" label="presentation"/>
  <atom:title></atom:title>
</atom:entry>'
    DOWNLOAD_TYPES = ['pdf', 'png', 'ppt', 'swf', 'txt']
    EXPORT_URI = 'http://docs.google.com/feeds/download/presentations/Export'
    
    def self.find(service, query, args = {})
      BaseObject::find(service, query, 'presentation', args)
    end
    
    def initialize(service, attributes = {})
      super(service, attributes)
      @xml = DOCUMENT_XML
    end
    
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