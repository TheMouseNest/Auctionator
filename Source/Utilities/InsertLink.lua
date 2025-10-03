function Auctionator.Utilities.InsertLink(link)
  if link ~= nil then
    if ChatFrameUtil and ChatFrameUtil.InsertLink then
      if not C_ChatInfo.InChatMessagingLockdown or not C_ChatInfo.InChatMessagingLockdown() then
        ChatFrameUtil.InsertLink(link)
      end
    else
      ChatEdit_InsertLink(link)
    end
  end
end
