classdef ADXLInterface < handle
    properties(Access = private)
        % Serial Port Related Variables
        serial_interface

        serial_port_address = "COM6"
        serial_port_running = false;
        % Class Properties
        update_interval = 100
        % Data
        t0 = -1;
        
    end
    properties(Access = public)
        count = 0;
        received_data = [];
    end
    methods(Access = public)
        function this = ADXLInterface(serial_port_address, baudrate)
            arguments
                serial_port_address {mustBeText}
                baudrate {mustBeNumeric}
            end
            this.serial_port_address = serial_port_address;
            this.serial_interface = serialport(serial_port_address, baudrate);
            configureTerminator(this.serial_interface,255)
            configureCallback(this.serial_interface,"off")
        end
        function this = set_serialport(this, serial_port_address, baudrate)
            arguments
                this
                serial_port_address {mustBeText}
                baudrate {mustBeNumeric}
            end
            this.serial_port_address = serial_port_address;
            this.serial_interface = serialport(serial_port_address, baudrate);
            configureTerminator(this.serial_interface,255)
            configureCallback(this.serial_interface,"off")
        end
        function this = start_reading(this)
            this.serial_port_running = true;
            flush(this.serial_interface)
            % while(read(this.serial_interface,1,"uint8")~=255), end
            configureCallback(this.serial_interface,"terminator", @(src, event) this.serial_port_callback(src))
        end
        function this = stop_reading(this)
            this.serial_port_running = false;
            configureCallback(this.serial_interface,"off")
        end
        function val = is_reading(this)
            val = this.serial_port_running;
        end
        function delete(this)
            if this.serial_port_running
                this.stop_reading();
            end
            if ~isempty(this.serial_interface)
                clear this.serial_interface;
            end
        end
    end
    methods(Access = private)
        function this = serial_port_callback(this, device)
            if(mod (this.count,this.update_interval) == 0)
                data = read(device,12*this.update_interval,"uint8")';
                [t,x,y,z,e] = this.process_ADXL_raw_data(uint8(data));
                this.received_data = [this.received_data [t;x;y;z;e]];
            end
            this.count = this.count+1;
        end
        function [t,x,y,z,enable]=process_ADXL_raw_data(this,raw_data)
            frame_divide_idxes = [0;find(raw_data==255)];
            frame_lengths = diff(frame_divide_idxes);
            valid_frame_idxes = frame_divide_idxes(frame_lengths==12);
            data_indexes = repmat(valid_frame_idxes',1,12)+repelem(1:12,1,length(valid_frame_idxes));
            raw_data = reshape(raw_data(data_indexes),[],12)';
            % raw_data = gpuArray(raw_data);
        
            t4 = uint32(bitor(bitshift(raw_data(1,:),4), bitshift(raw_data(2,:),-3)));
            t3 = uint32(bitor(bitshift(raw_data(2,:),5), bitshift(raw_data(3,:),-2)));
            t2 = uint32(bitor(bitshift(raw_data(3,:),6), bitshift(raw_data(4,:),-1)));
            t1 = uint32(bitor(bitshift(raw_data(4,:),7), raw_data(5,:)));
            
            x2 = uint16(bitshift(raw_data(6,:),-2));
            x1 = uint16(bitor(bitshift(raw_data(6,:),6),  raw_data(7,:)));
        
            y2 = uint16(bitshift(raw_data(8,:),-2));
            y1 = uint16(bitor(bitshift(raw_data(8,:),6),  raw_data(9,:)));
        
            z2 = uint16(bitshift(raw_data(10,:),-2));
            enable = bitand(uint8(1),bitshift(raw_data(11,:),-6));
            raw_data(11,:) = bitand(raw_data(11,:),uint8(63));
            z1 = uint16(bitor(bitshift(raw_data(10,:),6), raw_data(11,:)));
            
            t = bitshift(t4,24)+bitshift(t3,16)+bitshift(t2,8)+t1;
            x = bitshift(x2,8)+x1;
            y = bitshift(y2,8)+y1;
            z = bitshift(z2,8)+z1;
        
            if this.t0 < 0
                this.t0 = t(1);
            end
            t = t-this.t0;
            t(t<0) = t(t<0)+4294967295;
        end
    end
end

