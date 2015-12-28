#!/usr/bin/env ruby

require "net/http"
require_relative "dashlane"

def find_settings_file username
    # TODO: Support other OSes
    raise "Only OS X is supported" if !RUBY_PLATFORM =~ /darwin/

    profiles_path = "Library/Group Containers/5P72E3GC48.com.dashlane/Dashlane/profiles"
    settings_path = "Settings/localSettings.aes"

    path = File.join Dir.home, profiles_path, username, settings_path
    raise "Profile '#{username}' doesn't exist" if !File.exists? path

    path
end

def load_settings username, password
    blob = Base64.encode64 File.binread find_settings_file username
    decrypt_blob blob, password
end

def load_uki username, password
    xml = load_settings username, password
    REXML::Document.new(xml).text "/root/KWLocalSettingsManager/KWDataItem[@key='uki']"
end

def fetch username, uki
    uri = URI "https://www.dashlane.com/12/backup/latest"
    response = Net::HTTP.post_form uri, {
        login: username,
        lock: "nolock",
        timestamp: 1,
        sharingTimestamp: 0,
        uki: uki
    }

    raise "Fetch failed" if response.code != "200"

    response.body
end

username = File.read(".username").strip
password = File.read(".password").strip
uki = load_uki username, password
puts fetch username, uki
