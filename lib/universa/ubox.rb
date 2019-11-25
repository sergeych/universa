# THIS IS A WORK IN PROGRESS COULD VE CHANGED COMPLETELY, OR EVEN DROPPED. DO NOT USE!!!

=begin

U-Box is a special one-contract transactional filesystem-based storage to hold U packs. It is file based,
both file and extension are significant.

File name is:

<name>_<units>

where

- <name> is just a name of the pack. When unique name collides, <name> is appended with a serial <name><serial>.

extensions are:

.u - currently active U pack
.u1 - next U pack, exist while payment operation is in progress

.us file timestamp is used as FS lock flag. If it is newer than 45s, the ubox is considered locked. after it
    the cleanup procedure should be performed.

UBox wallet contains various assets that could be used to pay for transactions:

- ~/.universa/ubox contains all U-packs available for the system

- ~/.universa/ubox/inbox could be used to put U-packs in .unicon formaat to be automatically imported

=end

require 'fileutils'

class UBox

  def import contract: nil, path: "~/.universa/ubox"
    @path = path
    FileUtils.mkdir_p(path) unless File.exist?(path)
  end

end
