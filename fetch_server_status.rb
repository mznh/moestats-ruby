#!/usr/bin/env ruby


require 'socket'
require 'ipaddr'
require 'time'
require 'json'


class MoEServerViewer
  SERVER_STATUS ={
    2 => 'up',
    18 => 'lock',
    50 => 'busy',
    58 => 'down?',
  }
  def initialize
    @socket = UDPSocket.new()
    @up_server_ip = '150.95.62.67'
    @up_server_port = 11300

  end
  def finalize 
    @socket.close
  end

  def decode_status_code code
    status = SERVER_STATUS.fetch(code & 0xFF,nil)
    if status.nil? then
      'unknown_status'
    else
      status
    end
  end
  def send(data)
    @socket.send(data,0,@up_server_ip,@up_server_port)
  end

  def recv(length)
    @socket.recv(length)
  end

  def get_server_num
    data = "\x00\x00\x00\x03\x02"
    self.send(data)
    num,_ =  recv(8).unpack('N1N1')
    num
  end

  def init_request_server_info
    data = "\x00\x00\x00\x05\x02"
    self.send(data)
  end

  def fetch_server_info
    num = get_server_num
    res = []

    init_request_server_info
    num.times do
      ## logging info
      now = Time.now
      time_info = {
        :timestamp => now.to_i,
        :date => now.strftime("%Y%m%d"),
        :hour => now.strftime("%H"),
        :record_time => Time.at(now.to_i).to_s,
      }

      ## server info 
      data = recv(42)
      _, raw_ip_address, order, name = data.unpack("NLNZ*")
      status_code, login_now, login_max, reboot_time = data[22..].unpack("nNNN")
      server_info = {
        :name => name,
        :ip_address => IPAddr.new(raw_ip_address, Socket::AF_INET).to_s,
        :order => order,
        :status => decode_status_code(status_code),
        :login_now => login_now,
        :login_max => login_max,
        :reboot_time => Time.at(reboot_time).to_s
      }
      res << time_info.merge(server_info)
    end
    res 
  end
end


moe_server_viewer = MoEServerViewer.new()
moe_server_viewer.fetch_server_info.each do|st|
  puts st.to_json
end
