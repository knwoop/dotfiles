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

local function findToolbar(element, depth)
  if not element or depth > 4 then return nil end
  if element:attributeValue('AXRole') == 'AXToolbar' then return element end
  for _, child in ipairs(element:attributeValue('AXChildren') or {}) do
    local found = findToolbar(child, depth + 1)
    if found then return found end
  end
  return nil
end

local function toolbarMentions(toolbar, needle, depth)
  if not toolbar or depth > 4 then return false end
  local desc = toolbar:attributeValue('AXDescription') or ''
  local title = toolbar:attributeValue('AXTitle') or ''
  if desc:find(needle, 1, true) or title:find(needle, 1, true) then
    return true
  end
  for _, child in ipairs(toolbar:attributeValue('AXChildren') or {}) do
    if toolbarMentions(child, needle, depth + 1) then return true end
  end
  return false
end

local function launchChromeProfile(profileDir, profileName)
  return function()
    -- macOS' open ignores --profile-directory once Chrome is running, so we
    -- enumerate Chrome windows and focus one whose toolbar advertises the
    -- profile name (the avatar button is in the toolbar). Restricting the
    -- search to the toolbar avoids false matches from tab/bookmark titles.
    local chrome = hs.application.find('Google Chrome')
    if chrome then
      for _, win in ipairs(chrome:allWindows()) do
        local axWin = hs.axuielement.windowElement(win)
        local toolbar = axWin and findToolbar(axWin, 0)
        if toolbar and toolbarMentions(toolbar, profileName, 0) then
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
