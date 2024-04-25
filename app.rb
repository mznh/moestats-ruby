#!/usr/bin/env ruby
require "bundler/setup"

require "functions_framework"
require "base64"
require 'dotenv'
require 'date'

require "google/cloud/secret_manager/v1"
require "google/cloud/storage"

require "./moe-server-stat-fetcher"

def result_to_csv(server_data)
  keys = [:timestamp, :date, :hour, :record_time, :name, :ip_address, :order, :status, :login_now, :login_max, :reboot_time]
  server_text = server_data.map{|server|
    keys.map{|k|
      if server[k].class != String then
        server[k] 
      else
        "\"#{server[k]}\""
      end
    }.join(",")
  }.join("\n")+"\n"
  server_text
end

def fetch_and_write(logger)
  gcs_client = Google::Cloud::Storage.new(project_id: ENV['PROJECT_ID'])
  bucket = gcs_client.bucket(ENV['BUCKET_NAME'])
  ms = MoEServerStatFetcher.new()

  dt = DateTime.now.strftime("%Y%m%dT%H%M%S")
  file_path = "#{ENV['GCS_RAW_PATH']}/raw_#{dt}.csv"

  header_path = ENV['GCS_HEADER_PATH']
  composed_dt = DateTime.now.strftime("%Y%m")
  compoesd_file_path = "composed_test/#{composed_dt}.csv"
  # 本番切替時にはこれに変える
  #compoesd_file_path = "#{GCS_COMPOSED_PATH}/#{composed_dt}.csv"

  begin
    # fetch data and convert to csv
    server_data = ms.fetch_server_info
    server_text = result_to_csv(server_data)
    # その月のcomposedファイルがなければ作成
    if bucket.find_file(compoesd_file_path).nil? then
      header_file = bucket.file(header_path)
      header_file.copy(compoesd_file_path)
      logger.info("create new monthly file: #{compoesd_file_path}")
    end
    # write 
    bucket.create_file(StringIO.new(server_text),file_path,content_type: "text/csv") 
    logger.info("write raw file: #{file_path}")
    # compose
    raw_files = bucket.files(prefix: "raw/raw_")
    bucket.compose([compoesd_file_path] + raw_files,compoesd_file_path) do |f|
      f.content_type = "text/csv"
    end
    logger.info("complete composed: #{compoesd_file_path}")
  rescue => err
    logger.error ($!)
    logger.error (err)
  else
    # delete
    logger.info("delete raw file: #{file_path}")
    raw_files.each do |file|
      file.delete
    end
  end
end

FunctionsFramework.cloud_event "trigger_by_pubsub" do |event|
  fetch_and_write(logger)
end

if __FILE__ == $0 then
  require 'logger'
  logger = Logger.new(STDOUT)
  fetch_and_write(logger)
end

