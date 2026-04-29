hs.alert.show('Config loaded')

-- Reload
hs.hotkey.bind({ 'cmd', 'alt', 'ctrl' }, 'R', function()
  hs.reload()
end)

local function keyStroke(mod, key)
  return function() hs.eventtap.keyStroke(mod, key, 1000) end
end

local function keyStrokes(text)
  return function() hs.eventtap.keyStrokes(text) end
end

local function launch(app)
  return function() hs.application.launchOrFocus('/Applications/' .. app .. '.app') end
end

local function axTreeContains(element, needle, depth)
  if not element or depth > 6 then return false end
  local desc = element:attributeValue('AXDescription') or ''
  local title = element:attributeValue('AXTitle') or ''
  local value = element:attributeValue('AXValue') or ''
  if type(value) ~= 'string' then value = '' end
  if desc:find(needle, 1, true) or title:find(needle, 1, true) or value:find(needle, 1, true) then
    return true
  end
  local children = element:attributeValue('AXChildren') or {}
  for _, child in ipairs(children) do
    if axTreeContains(child, needle, depth + 1) then return true end
  end
  return false
end

local function launchChromeProfile(profileDir, profileName)
  return function()
    -- macOS' open ignores --profile-directory once Chrome is running, so we
    -- enumerate Chrome windows and focus one whose AX tree advertises the
    -- profile (the avatar button usually carries the profile name).
    local chrome = hs.application.find('Google Chrome')
    if chrome then
      for _, win in ipairs(chrome:allWindows()) do
        local axWin = hs.axuielement.windowElement(win)
        if axWin and axTreeContains(axWin, profileName, 0) then
          win:focus()
          return
        end
      end
    end
    hs.execute("open -na 'Google Chrome' --args --profile-directory='" .. profileDir .. "'")
  end
end

local function remap(mod, key, pressedFn, repeatFn)
  hs.hotkey.bind(mod, key, pressedFn, nil, repeatFn)
end

local function remapRepeat(mod, key, fn)
  remap(mod, key, fn, fn)
end

-- shortcuts
-- remapRepeat({'cmd'}, 'Y', keyStroke({'cmd', 'shift'}, 'Z'))
remap({ 'cmd', 'ctrl' }, 't', launch('Ghostty'))
remap({ 'cmd', 'ctrl' }, 'c', launchChromeProfile('Profile 1', 'kauche'))
remap({ 'cmd', 'ctrl' }, 'p', launchChromeProfile('Profile 5', 'kenta'))
remap({ 'cmd', 'ctrl' }, 's', launch('Slack'))

deleteEvent = hs.eventtap.event.newKeyEvent({}, "delete", true)
repeatTimer = nil

downFn = function()
  deleteEvent:post()
  repeatTimer = hs.timer.doAfter(hs.eventtap.keyRepeatDelay(), function()
    repeatTimer = hs.timer.doEvery(hs.eventtap.keyRepeatInterval(), function()
      deleteEvent:post()
    end)
  end)
end

upFn = function()
  if repeatTimer then
    repeatTimer:stop()
    repeatTimer = nil
  end
end

hs.hotkey.bind({ "ctrl" }, "h", downFn, upFn, nil)
