require 'optparse'
require 'ostruct'
require 'ansi/code'
require 'universa'
require 'universa/tools'

include Universa

class MessageException < Exception; end

def error message
  raise MessageException, message
end

using Universa

def human_to_i value, factor = 1000
  head, tail = value[0...-1], value[-1]
  case tail
    when 'k', 'K'
      head.to_i * 1000
    when 'M', 'm'
      head.to_i * factor * factor
    when 'G', 'g'
      head.to_i * factor * factor * factor
    else
      value.to_t
  end
end

def seconds_to_hms seconds
  mm, ss = seconds.divmod(60)
  hh, mm = mm.divmod(60)
  "%d:%02d:%02d" % [hh, mm, ss]
end

# Show help it nothing to do
ARGV << "-h" if ARGV == []

class KeyTool

  def initialize
    @require_password = true
    @autogenerate_password = false
    @tasks = []
    @rounds = 1000000
    init_parser()
  end

  def task &block
    @tasks << block
  end

  def session_password
    @require_password or return nil
    @session_password ||= begin
                            if @autogenerate_password
                              psw = 29.random_alnums
                              puts "Autogenerated password: #{ANSI.bold { psw }}"
                              psw
                            else
                              puts "\nPlease enter password for key to be generated"
                              psw1 = STDIN.noecho(&:gets).chomp
                              puts "Please re-enter the password"
                              psw2 = STDIN.noecho(&:gets).chomp
                              psw1 == psw2 or error "passwords do not match"
                              psw1.length < 8 and error "password is too short"
                              psw1
                            end
                          end
  end

  def output_file(extension = nil, overwrite_existing_name = nil)
    name = @output_file
    if !name
      (overwrite_existing_name && @overwrite) or error "specify output file with -o / --output"
      name = overwrite_existing_name
    end
    extension && !name.end_with?(extension) ? "#{name}#{extension}" : name
  end

  def load_key(name, allow_public = false)
    packed = open(name, 'rb') { |f| f.read } rescue error("can't read file: #{name}")
    begin
      PrivateKey.from_packed(packed)
    rescue Exception => e
      if e.message.include?('PasswordProtectedException')
        puts "\nThe key is password-protected"
        while (true)
          puts "\renter password for #{name}:"
          password = STDIN.noecho(&:gets).chomp
          STDOUT << ANSI.faint { "trying to decrypt..." }
          key = PrivateKey.from_packed(packed, password: password) rescue nil
          key and break key
        end
      elsif allow_public
        begin
          PublicKey.from_packed(packed)
        rescue
          error "can't load the private/public key (file corrupt?)"
        end
      else
        error "can't load the private key (file corrupt?)"
      end
    end
  end

  def check_overwrite output
    error "File #{output} already exists" if File.exists?(output) && !@overwrite
  end

  def save_key name, key
    open(name, 'wb') { |f|
      f << if @require_password
             password = session_password
             puts "\nEncrypting key with #@rounds PBKDF rounds..."
             key.pack_with_password(password, @rounds)
           else
             key.pack()
           end
    }
  end

  def init_parser
    opt_parser = OptionParser.new { |opts|
      opts.banner = ANSI.bold { "\nUniversa Key tool #{Universa::VERSION}" }
      opts.separator ""

      opts.on("--no-password",
              "create resources not protected by password. Not recommended.") { |x|
        @require_password = x
      }

      opts.on("-a", "--autogenerate_password",
              "the new secure password will be generated and shown on the console",
              "while the password is safe, printing it out to the console may not.",
              "Normally, system promts the password on the console that is",
              "more secure") { |x|
        @autogenerate_password = x
      }

      opts.on("-o FILE", "--output FILE", "file name for the output file") { |f|
        @output_file = f
      }

      opts.on("-F", "--force", "force overwrite file") {
        @overwrite = true
      }

      opts.on("-g SIZE", "--generate SIZE", "generate new private key of the specified bis size") { |s|
        task {
          strength = s.to_i
          case strength
            when 2048, 4096
              task {
                # check we have all to generate...
                output = output_file(".private.unikey")
                check_overwrite(output)
                key = PrivateKey.new(strength)
                save_key(output, key)
                puts "\nNew private key is generated: #{output}"
              }
            else
              error "Only supported key sizes are 2048, 4096"
          end
        }
      }

      opts.on("-u FILE", "--update FILE", "update password on the existing key (also add/remove",
              "requires -o output_file or --overwrite to change it in place") { |name|
        task {
          output = output_file(".private.unikey", name)
          check_overwrite output
          key = load_key(name)
          puts("\rKey loaded OK                       ")
          save_key output, key
        }
      }

      opts.on("-r ROUNDS", "--rounds ROUNDS", "how many PBKDF2 rounds to use when saving with password",
              "(1 million by default, the more the better, but takes time)") { |r|
        @rounds = human_to_i(r)
        @rounds < 100000 and error "To few rounds, use at least 100000"
      }

      opts.on("-p FILE", "--public FILE", "extract public key. If output file is not specified,",
              "prints as universa text object to the standard output") { |name|
        task {
          key = load_key(name, true)
          if @output_file
            open(output_file(".public.unikey"), 'wb') { |f| f << key.pack() }
          else
            puts format_text_object(key.pack(), "public key", fileName: name)
            # puts "not yet implemented #{key.long_address.to_s}"
          end
        }
      }

      opts.on("-s FILE", "--show FILE", "show key information") { |name|
        task {
          key = load_key(name, true)
          is_private = key.is_a? PrivateKey
          puts "\r----------------------------------------------------------------------------------------"
          puts "#{is_private ? 'Private' : 'Public'} key, #{key.info.getKeyLength() * 8} bits\n"
          puts "Short address : #{ANSI.bold { key.short_address.to_s }}"
          puts "Long  address : #{ANSI.bold { key.long_address.to_s }}"
        }
      }

      opts.separator ""

      def sample(text)
        "    " + ANSI.bold { ANSI.green { text } }
      end

      opts.on_tail("-h", "--help", "Show this message") do
        puts opts
        puts <<-End

#{ANSI.bold { "Usage samples:" }}

Generate new key 'foo.private.unikey' - will ask password from console (notice extension will be added automatically)
  
#{sample "unikeys -g 2048 -o foo"}

Show foo addresses:

#{sample "unikeys -s foo.private.unikey"}

Change password of the foo key and save it into new file bar.private.unikey (keeping both for security), will ask
new password from console

#{sample "unikeys -u foo.private.unikey -o bar"}

Change password in place (overwriting old file)

#{sample "unikeys -u foo.private.unikey -f"}

See project home page at #{ANSI.underline { "https://github.com/sergeych/universa" }}

        End
        exit
      end

      opts.on_tail("-v", "--version", "Show versions") do
        puts "Universa core version: #{Service.umi.core_version}"
        puts "UMI version          : #{Service.umi.version}"
        client = Universa::Client.new
        puts "Connected nodes      : #{client.size}"
        exit
      end
    }

    begin
      opt_parser.order!
      if @tasks.empty?
        puts "nothing to do. Please specify one of: -g, -s or -u. See help for more (-h)."
      else
        @tasks.each { |t| t.call }
      end
    rescue MessageException, OptionParser::ParseError => e
      STDERR.puts ANSI.red { ANSI.bold { "\nError: #{e}\n" } }
      exit(1000)
    rescue Interrupt
      exit(1010)
    rescue
      STDERR.puts ANSI.red { "\n#{$!.backtrace.reverse.join("\n")}\n" }
      STDERR.puts ANSI.red { ANSI.bold { "Error: #$! (#{$!.class.name})" } }
      exit(2000)
    end
  end
end

KeyTool.new()
