module GDocs4Ruby
  class Spreadsheet < Document
    DOCUMENT_XML = '<?xml version="1.0" encoding="UTF-8"?>
<atom:entry xmlns:atom="http://www.w3.org/2005/Atom">
  <atom:category scheme="http://schemas.google.com/g/2005#kind"
      term="http://schemas.google.com/docs/2007#spreadsheet" label="spreadsheet"/>
  <atom:title></atom:title>
</atom:entry>'
    DOWNLOAD_TYPES = ['xls', 'csv', 'pdf', 'ods', 'tsv', 'html']
    EXPORT_URI = 'http://spreadsheets.google.com/feeds/download/spreadsheets/Export'
    
    def self.find(service, query, args = {})
      BaseObject::find(service, query, 'spreadsheet', args)
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
      service.reauthenticate('wise')
      ret = service.send_request(GData4Ruby::Request.new(:get, EXPORT_URI, nil, nil, {"key" => @id.gsub(/\w.*:/, ""),"exportFormat" => type}))
      service.reauthenticate()
      ret.body
    end
  end
end