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

local function launchChromeProfile(profileDir, titleSuffix)
  return function()
    -- macOS' open ignores --profile-directory once Chrome is running, so we
    -- find an existing window for this profile ourselves. Chrome always
    -- appends " - Google Chrome - <profile suffix>" to its window titles
    -- when multiple profiles are active; that suffix is set by Chrome and
    -- can't be spoofed by page or tab content, so an end-of-title match
    -- is the most reliable signal we have.
    local chrome = hs.application.find('Google Chrome')
    if chrome then
      for _, win in ipairs(chrome:allWindows()) do
        local title = win:title() or ''
        if #title >= #titleSuffix and title:sub(-#titleSuffix) == titleSuffix then
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
remap({ 'cmd', 'ctrl' }, 'c', launchChromeProfile('Profile 1', '(kauche)'))
remap({ 'cmd', 'ctrl' }, 'p', launchChromeProfile('Profile 5', '(personal)'))
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
