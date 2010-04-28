require 'gdocs4ruby/base' 
require 'gdocs4ruby/base_object'
require 'gdocs4ruby/folder'
require 'gdocs4ruby/document'
require 'gdocs4ruby/spreadsheet'
require 'gdocs4ruby/presentation'

module GDocs4Ruby

#The service class is the main handler for all direct interactions with the 
#Google Calendar API.  A service represents a single user account.  Each user
#account can have multiple calendars, so you'll need to find the calendar you
#want from the service, using the Calendar#find class method.
#=Usage
#
#1. Authenticate
#    service = Service.new
#    service.authenticate("user@gmail.com", "password")
#
#2. Get Document List
#    documents = service.documents
#
#3. Get Folder List
#    folders = serivce.folders
#
DOCUMENT_LIST_FEED = "https://docs.google.com/feeds/documents/private/full"
FOLDER_LIST_FEED = "http://docs.google.com/feeds/documents/private/full/-/folder?showfolders=true"
  class Service < GData4Ruby::Service    
    #Accepts an optional attributes hash for initialization values
    def initialize(attributes = {})
      super(attributes)
    end
  
    # The authenticate method passes the username and password to google servers.  
    # If authentication succeeds, returns true, otherwise raises the AuthenticationFailed error.
    def authenticate(username, password, service='writely')
      super(username, password, service)
    end
    
    def reauthenticate(service='writely')
      authenticate(@account, @password, service)
    end
    
    #Returns an array of Folder objects for each folder associated with 
    #the authenticated account.
    def folders
      if not @auth_token
         raise NotAuthenticated
      end
      ret = send_request(GData4Ruby::Request.new(:get, FOLDER_LIST_FEED))
      folders = []
      REXML::Document.new(ret.body).root.elements.each("entry"){}.map do |entry|
        entry = GData4Ruby::Utils::add_namespaces(entry)
        folder = Folder.new(self)
        puts entry.to_s if debug
        folder.load("<?xml version='1.0' encoding='UTF-8'?>#{entry.to_s}")
        folders << folder
      end
      return folders
    end
    
    def files
      contents = []
      ret = send_request(GData4Ruby::Request.new(:get, DOCUMENT_LIST_FEED))
      xml = REXML::Document.new(ret.body)
      xml.root.elements.each('entry'){}.map do |ele|
        ele = GData4Ruby::Utils::add_namespaces(ele)
        obj = BaseObject.new(self)
        obj.load(ele.to_s)
        case obj.type
          when 'document'
            doc = Document.new(self)
          when 'spreadsheet'
            doc = Spreadsheet.new(self)
          when 'presentation'
            doc = Presentation.new(self)
        end
        doc.load(ele.to_s)
        contents << doc
      end
      return contents
    end
  end
end