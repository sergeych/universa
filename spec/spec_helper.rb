require "bundler/setup"
require "universa"

include Universa

RSpec.configure do |config|
  # Enable flags like --only-failures and --next-failure
  # config.example_status_persistence_file_path = ".rspec_status"

  config.expect_with :rspec do |expectations|
    expectations.syntax = [:should, :expect]
  end
  config.mock_with :rspec do |mocks|
    mocks.syntax = :should
  end

  # Disable RSpec exposing methods globally on `Module` and `main`
  # config.disable_monkey_patching!

  # config.expect_with :rspec do |c|
  #   c.syntax = :should
  # end
end


module TestKeys

  def test_keys
    # $testKeys ||= 10.times.map { PrivateKey.new 2048 }
    # $testKeys.each { |k|
    #   puts "keys << PrivateKey.from_packed( <<End\n#{Base64.encode64(k.pack)}End\n)"
    # }
    $testKeys ||= begin
      keys = []
      keys << PrivateKey.from_packed(Base64.decode64 <<End
JgAcAQABvID1DCWaq0CGO4fJBJvpBah8RiDBA+OKNw/CjyW2ZCawD/pSnB4B
bR3SUruQjUhPyQ37xMzYZnXS6jMm4qNI5YlAAjapa5FRI45SLu6vR6UlRdwS
W/viXmoLyrUKreQcCseiIC6uXi5serHxoeyYUHlyPRkT83+xAzf37ePWiNbm
3byA46XKSW6oKLce09TiFfxJSuLSP+Iqfjhier/oEAeu2qzklxsKIiqAE2gV
wFQ4nh8HrySE0WSfiXQ3CEONByZyz0NmYE7XozHf9i6aMhfFNAD0oIbl5Xim
4hBOhbiALsxgNm+UTJ0tnj6jpw8UZnyty4vzgUCMvywolKmJcSqlxLU=
End
      )
      keys << PrivateKey.from_packed(Base64.decode64 <<End
JgAcAQABvID6g6V+cb5OqW4A88LaoROKe+85y9umQ6sXm16eSV2YN57m+jMe
stsOSYhpDDpE/JI900tfmFjT8APJbHAVJQ+KkBrmiW2gS7WgUO5KTCxb6sCh
aVeItGgYOaQsaTZXkT6tYN0HzlQxh4z6AmZz8x2/1+t/TkX0X5NcTnzoIxXr
GbyAxtmNP9Fjaqwe/fZeFg2pitJznktotCzuFB/vCj8XdUV7ZfVlDxd/+0jX
tTvjxmSxYRwdP6iV2eYwHQytYHqRrJR7ayh9TRAa1rgRVE91swU7Q+DvQI8U
t0oQF4at0ztDRLitBtrO2HxxGa9okk0TtVZUTv3BWbqAtwXUqFhCUW8=
End
      )
      keys << PrivateKey.from_packed(Base64.decode64 <<End
JgAcAQABvID7gnbXN7XMfjqrLuYqdAObvIgQa4/DzH9n6QiTSmgtKUAs7+T3
hDs1h/BIuI0uwH5NBCXM9JpSruRt7CH2kJntyMyqcJGo9ftZ8wBJsWBaURaE
Xy2bVYfMv18dmOiKvLp4DIY30ctfCSVroSpnj2udEIQGLRso+p+jz8zszBSY
T7yA3OujqVc4THtMSYLALxh0/BwQv5V3Br5Cu9VPFkazovJlxn/aGSfo6TYa
lb5FCVvy+tR7ZUD16RhXwnPtf8hlQYcp5+1JJYHnXnZx+/QdC1zHgsnrlrUK
LDA3NWCnlEDzkeB99V/PKVjNwG7nrOfbgBQsibZ4dS6/GU640/zYoSE=
End
      )
      keys << PrivateKey.from_packed(Base64.decode64 <<End
JgAcAQABvID6qBuk4gGy5E6yPBFMcRHMsYOZ3BYt8KrvQS4CVwo45g4KDpXX
r+6DBoCBm+F59Pl0oQPi9ISlJULASf/QjhU15WQLhfOz1CeDwyCw/zJbejTA
X0EB/ObzxHLCnc/UvvGLuRxT5u+y2eAu8zCMOh9k1wjCLssaI4WiOfT4pKM8
sbyA0SvBAwhDKZZ1wfnbL+1F31qZU1OtUAv9cLPP4RzRkyx3pM0GnDNWAhkC
LCVd+EVt2LrM2ooDDzSUpShRFaGSOHJZTU5z1ex4chERKQapTS7/etO/nZ/y
Xd0dH1S/zW9Gw66x5qoCC9G+3xKeYi/axRrRrB0Fxkk+s/QHz1shnMs=
End
      )
      keys << PrivateKey.from_packed(Base64.decode64 <<End
JgAcAQABvIDhqLaNuMf5jU25n/iZ/Iy24IK5+fVkFISAulYN6bmbeeGyQiJ0
JO4cLXllSCOaACxdDVbtRVj/INybcCXiJ0I/ABoyDxofSgNZ9yVcVEkJgCFh
HEa0vumkphvVLGIxcc/G2F9/JWnLiyFVINbp0odYfm6Rkp1g7BZXHdnkjayM
vbyA3NGBxmZ6yhiBJWL7vkGKYaddvW4/bVGbGWCw84qOYjPI+DLGV9MadXJ6
MtEVdk9B3dA1C5RlzM2SWf5pjX+TNIoCH8jc9nIxY8PLtKm11NpHogbe67qy
f4PNdFCFptopR66Uipr1NrJ9KhPgFcDWHEdWRHE77fzg2kVGRPCEnPk=
End
      )
      keys << PrivateKey.from_packed(Base64.decode64 <<End
JgAcAQABvID01bySuu6Y01esyw9VZ6Fl5FBeZ5gHuqIHp8WLm6z4yHsrddiC
zp5yj9JpyauyLlil+SdVQF7WoUWd6epvsHiCgF5IT3uOkeFDgsox8xvOvZxH
STOQGKq4H9OwKTcl3y8H3I/v8Y1pDJ4dm1EbFkVF9zAcB64Frvvm+zHSBOnM
RbyA6MwaFKCpYGJdI63tkVA0vn5teTNdYvDVniJd9IQMFgFjpcD0n1RVXYXZ
ufvEPDALLF2WsHyaGFu4KrLAQZXkrWurMp6eYO5bJKMQ28o2YOIhEHfTymRv
FT43xWGfh8RxGlt3E4DT4u/kFAw6nAZtXvC/GChYCC717MEW7LINkn0=
End
      )
      keys << PrivateKey.from_packed(Base64.decode64 <<End
JgAcAQABvID76iKhuwtIgpqiKNeardd98lKsaC0L5sYONgXhgP1AbxdgiFF0
DgA6G6WolDimhK3Xau6bZ0Lc2HibVMi88TRILLKmDBVCy7eykPBcVr1PTOPp
S3fJpWuZr/3/nQbrqqDhQGm1UIBAH6B/RT/WcmPVM53ULSWHwsDOXTweeDU/
qbyAxjw38REUCaezqYHqrvR1LUXSah37xzkTPnz9Oz/98ENzQDeOqJ92TLW9
ruAHcs3fjPEEwRGkbc2i0/+PEP7WMsGifRaXmF+mVrD2XsTsaQcedIDR82MU
I+t6xG9AXb6EoEyIG+GXtIoMSHiXs9FugAmw0jYZ81RnT5KzHVrNd7U=
End
      )
      keys << PrivateKey.from_packed(Base64.decode64 <<End
JgAcAQABvID4gePYZM7hojtHDxReZNLeqLAUSdeiF0YNIcNP/Rz3nH33Z41A
45xU+iyf+u3jM5T262i0AT6Xby52XxZ+tpz+ynsuQXTUOxZI5wfO2hopcY0Z
L4AEVUUEdXeozzUyfI2FTeqLNFV73XZ9ZL+BIO/gkX9pjUUpt1bTJyquTxpw
P7yA0kxC+/XNLmkrql2Y1eRxu+KB+lwhlkwh18OIkKzJGg6MrapFHo0+6BnS
RToaDspdjzJONk47IYN8fCc6pGGf8xXCztYUVh53/wEt22bKZ1KVLsC35yr7
sJTubI1xw+/Khx8QLe3fkWovXrqEVeKi+p9zP9ddBvTSxaRd2FXIgP0=
End
      )
      keys << PrivateKey.from_packed(Base64.decode64 <<End
JgAcAQABvIDzqprWVUyG0NN9g60TFylld8U4JV51GT2NfcQwKex95LJRMcVW
8NRayHbe2aMaAREkQtmI4wuJPAEkz/TmGrqEUDZyEmYzTr6ZOgBAQAeWA0Iw
qyOy18xHS949WTAM4zMU7rVjjSKSMU3NOsOPLQtCfgbzAewcwdnuGpnW1adR
JbyA0UNCEdkeOvGxQKFO405tMrmjj2BkcSk6oMnLKFyyZwPOB2OnNG12qjuI
xvatEObSr9zqb6CLq/5KrWVo689W4PbZ9sgpV4R58AurQVMhFKq+xbm70Dpe
Lu5RWs1v7gOOUUevG1rrk91itgLudq1av+CGEW5t/qJc75NaMP9CSc8=
End
      )
      keys << PrivateKey.from_packed(Base64.decode64 <<End
JgAcAQABvIDcHgUtK50mYSGyct6XYkBtw7RLTG3isIUSWu2IkfIR/nNZslGS
sMp9U/bmTfKnJCPpuPLQ0bgrNXV9ub9NKNgEE1Aze3Dfwq7+N5tpERGS49u3
aAcQN/+tzmH0Pi4QoKB6RW2VHHPvJ9wzFtaJsdCkr+ULayNZhOCxsZRV8mlF
lbyA06K4KjvCCUedmZ6RmG/9fqSnvVEMUDaV8BxWyDy43dvkCwsTcRS+GLhg
KiIYLzj4khUWroF9G44zpMqUhaslC6qyQGfTE8oIP85cwzj5oW6eCWbRyfOu
SUeNfoKa69d7AMv7bsvSMjFGDcZg20MdsYykf0+DCnnO/Li9SGQJmek=
End
      )
      keys
    end
  end
end

