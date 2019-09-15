--------------------------------------------------------------------------------
-- Let's Pug (c) 2019 by Siarkowy <http://siarkowy.net/letspug>
-- Released under the terms of BSD 2.0 license.
--------------------------------------------------------------------------------

--------------------------------------------------------------------------------
-- Guild API wrappers
--------------------------------------------------------------------------------

--- Returns guild roster index for specified player name, nil if not found.
function LetsPug:GetGuildRosterIndexByName(name)
    for i = 1, GetNumGuildMembers(true) do
        if GetGuildRosterInfo(i) == name then
            return i
        end
    end
end

--- Returns guild roster info for given player.
function LetsPug:GetGuildRosterInfoByName(name)
    local idx = self:GetGuildRosterIndexByName(name)
    return GetGuildRosterInfo(idx or 0)
end

--- Returns public note for given player.
function LetsPug:GetGuildRosterPublicNoteByName(name, _note)
    return _note or select(7, self:GetGuildRosterInfoByName(name))
end

--- Sets public note for given player.
function LetsPug:SetGuildRosterPublicNoteByName(name, note)
    if not self.HasPassed(8, "SetGuildRosterPublicNoteByName") then return end
    GuildRosterSetPublicNote(self:GetGuildRosterIndexByName(name), note)
end

--------------------------------------------------------------------------------
-- Save info handling
--------------------------------------------------------------------------------

--- Extracts save info from player note.
function LetsPug:ExtractNoteSaveInfo(note)
    return (note or ""):match("!(.+)")
end

--- Replaces existing save info in guild note with provided one.
function LetsPug:CombineNoteSaveInfo(current_note, save_info)
    current_note = (current_note or ""):gsub("!.*", "")
    save_info = save_info or ""
    local excl = save_info ~= "" and "!" or ""
    return format("%s%s%s", current_note:sub(1, 31 - save_info:len() - 1), excl, save_info)
end

--- Checks player save info and updates guild note if needed.
function LetsPug:CheckGuildRosterPublicNote()
    local current_note = self:GetGuildRosterPublicNoteByName(self.player)
    local note_info = self:ExtractNoteSaveInfo(current_note)
    local current_info = self:EncodeSaveInfo()

    if note_info ~= current_info then
        local new_note = self:CombineNoteSaveInfo(current_note, current_info)
        if self.debug then
            self:Print(("CheckGuildRosterPublicNote: old=%q new=%q"):format(current_note or "", new_note or ""))
        end
        self:SetGuildRosterPublicNoteByName(self.player, new_note)
    end
end

--- Synchronizes player save info from guild notes. Skips currently logged in player.
-- Triggers LETSPUG_GUILD_SAVEINFO_UPDATE(player, info) event on any change detected.
function LetsPug:SyncFromGuildRosterPublicNotes()
    for i = 1, GetNumGuildMembers(true) do
        local player, _, _, _, _, _, note, _, _, _, class = GetGuildRosterInfo(i)
        local note_info = self:ExtractNoteSaveInfo(note)
        local current_info = self:GetPlayerSaveInfo(player)
        if note_info and note_info ~= current_info and player ~= self.player then
            self:RegisterPlayerSaveInfo(player, note_info)
            self:RegisterPlayerClass(player, class)
            self:SendMessage("LETSPUG_GUILD_SAVEINFO_UPDATE", player, note_info)
        end
    end
end

--------------------------------------------------------------------------------
-- Tests
--------------------------------------------------------------------------------

do
    local assertEqual = LetsPug.assertEqual

    assertEqual(LetsPug:ExtractNoteSaveInfo("abc!def!ghi"), "def!ghi")
    assertEqual(LetsPug:ExtractNoteSaveInfo("abc!def"), "def")
    assertEqual(LetsPug:ExtractNoteSaveInfo("abc!"), nil)
    assertEqual(LetsPug:ExtractNoteSaveInfo("!def"), "def")
    assertEqual(LetsPug:ExtractNoteSaveInfo("abc"), nil)
    assertEqual(LetsPug:ExtractNoteSaveInfo(""), nil)
    assertEqual(LetsPug:ExtractNoteSaveInfo(nil), nil)

    assertEqual(LetsPug:CombineNoteSaveInfo("abc!def!ghi", "A0101"), "abc!A0101")
    assertEqual(LetsPug:CombineNoteSaveInfo("abc!def", "A0101"), "abc!A0101")
    assertEqual(LetsPug:CombineNoteSaveInfo("abc!", "A0101"), "abc!A0101")
    assertEqual(LetsPug:CombineNoteSaveInfo("!def", "A0101"), "!A0101")
    assertEqual(LetsPug:CombineNoteSaveInfo("abc", "A0101"), "abc!A0101")
    assertEqual(LetsPug:CombineNoteSaveInfo("", "A0101"), "!A0101")
    assertEqual(LetsPug:CombineNoteSaveInfo(nil, "A0101"), "!A0101")

    assertEqual(LetsPug:CombineNoteSaveInfo("abc!def!ghi", ""), "abc")
    assertEqual(LetsPug:CombineNoteSaveInfo("abc!def", ""), "abc")
    assertEqual(LetsPug:CombineNoteSaveInfo("abc!", ""), "abc")
    assertEqual(LetsPug:CombineNoteSaveInfo("!def", ""), "")
    assertEqual(LetsPug:CombineNoteSaveInfo("abc", ""), "abc")
    assertEqual(LetsPug:CombineNoteSaveInfo("", ""), "")
    assertEqual(LetsPug:CombineNoteSaveInfo(nil, ""), "")

    assertEqual(LetsPug:CombineNoteSaveInfo("abc!def!ghi", nil), "abc")
    assertEqual(LetsPug:CombineNoteSaveInfo("abc!def", nil), "abc")
    assertEqual(LetsPug:CombineNoteSaveInfo("abc!", nil), "abc")
    assertEqual(LetsPug:CombineNoteSaveInfo("!def", nil), "")
    assertEqual(LetsPug:CombineNoteSaveInfo("abc", nil), "abc")
    assertEqual(LetsPug:CombineNoteSaveInfo("", nil), "")
    assertEqual(LetsPug:CombineNoteSaveInfo(nil, nil), "")
end
