-- drift
-- multi-track MIDI sequencer
-- independent non-integer rates for metric drift
--
-- K3: resync all tracks
-- PARAMS: rate, vel, duration, channel per track

local midi_out = midi.connect(1)

local tracks = {
  {
    name     = "kit 1",
    mode     = "trigger",
    channel  = 1,
    notes    = { 60 },
    rate     = 1.0,
    vel      = 110,
    duration = 0.05,
    active   = true,
  },
  {
    name     = "kit 2",
    mode     = "trigger",
    channel  = 1,
    notes    = { 61 },
    rate     = 0.75,
    vel      = 90,
    duration = 0.05,
    active   = true,
  },
  {
    name     = "kit 3",
    mode     = "trigger",
    channel  = 1,
    notes    = { 62 },
    rate     = 0.25,
    vel      = 90,
    duration = 0.05,
    active   = true,
  },
  {
    name     = "kit 4",
    mode     = "trigger",
    channel  = 1,
    notes    = { 63 },
    rate     = 0.5,
    vel      = 90,
    duration = 0.05,
    active   = true,
  },
  {
    name     = "kit 5",
    mode     = "trigger",
    channel  = 1,
    notes    = { 64 },
    rate     = 0.5,
    vel      = 90,
    duration = 0.05,
    active   = true,
  },
  {
    name     = "kit 6",
    mode     = "trigger",
    channel  = 1,
    notes    = { 65 },
    rate     = 0.5,
    vel      = 90,
    duration = 0.05,
    active   = true,
  },
  {
    name     = "kit 7",
    mode     = "trigger",
    channel  = 1,
    notes    = { 66 },
    rate     = 0.5,
    vel      = 90,
    duration = 0.05,
    active   = true,
  },
  {
    name     = "kit 8",
    mode     = "trigger",
    channel  = 1,
    notes    = { 66 },
    rate     = 0.5,
    vel      = 90,
    duration = 0.05,
    active   = true,
  },
  {
    name     = "kit 9",
    mode     = "trigger",
    channel  = 1,
    notes    = { 67 },
    rate     = 0.5,
    vel      = 90,
    duration = 0.05,
    active   = true,
  },
  {
    name     = "kit 10",
    mode     = "trigger",
    channel  = 1,
    notes    = { 68 },
    rate     = 0.5,
    vel      = 90,
    duration = 0.05,
    active   = true,
  },
  {
    name     = "kit 11",
    mode     = "trigger",
    channel  = 1,
    notes    = { 69 },
    rate     = 0.5,
    vel      = 90,
    duration = 0.05,
    active   = true,
  },
  {
    name     = "kit 12",
    mode     = "trigger",
    channel  = 1,
    notes    = { 70 },
    rate     = 0.5,
    vel      = 90,
    duration = 0.05,
    active   = true,
  },
  {
    name     = "synth A",
    mode     = "synth",
    channel  = 2,
    notes    = { 48, 51, 55, 58, 60 },
    rate     = 1.5,
    vel      = 80,
    duration = 0.3,
    active   = true,
  },
  {
    name     = "synth B",
    mode     = "synth",
    channel  = 3,
    notes    = { 36, 43, 48, 55 },
    rate     = 3.7,
    vel      = 70,
    duration = 0.5,
    active   = true,
  },
}

local note_index = {}
local coroutines  = {}

-- -------------------------------------------------------------------------
-- HELPERS
-- -------------------------------------------------------------------------

local function next_note(i)
  local t   = tracks[i]
  local len = #t.notes
  if note_index[i] == nil then note_index[i] = 1 end
  local n = t.notes[note_index[i]]
  note_index[i] = (note_index[i] % len) + 1
  return n
end

local function fire_note(i)
  local t    = tracks[i]
  local note = next_note(i)
  midi_out:note_on(note, t.vel, t.channel)
  clock.sleep(t.duration)
  midi_out:note_off(note, 0, t.channel)
end

local function stop_track(i)
  if coroutines[i] ~= nil then
    clock.cancel(coroutines[i])
    coroutines[i] = nil
    for _, note in ipairs(tracks[i].notes) do
      midi_out:note_off(note, 0, tracks[i].channel)
    end
  end
end

local function run_track(i)
  coroutines[i] = clock.run(function()
    clock.sleep(i * 0.01)
    while true do
      if tracks[i].active then
        fire_note(i)
      end
      clock.sleep(tracks[i].rate)
    end
  end)
end

local function start_track(i)
  stop_track(i)
  run_track(i)
end

-- -------------------------------------------------------------------------
-- PARAMS
-- [L] No BPM param -- when norns is slaved to Deluge MIDI clock,
-- clock.set_tempo() is unavailable. norns follows incoming tempo.
-- clock.get_tempo() still works for reading/display.
-- -------------------------------------------------------------------------

local function setup_params()

  for i, t in ipairs(tracks) do
    local pfx = "t" .. i .. "_"

    params:add_option(pfx .. "active", "t" .. i .. " " .. t.name .. " on", {"yes","no"}, 1)
    params:set_action(pfx .. "active", function(v)
      tracks[i].active = (v == 1)
    end)

    params:add_control(
      pfx .. "rate",
      "t" .. i .. " rate",
      controlspec.new(0.1, 16.0, "lin", 0.05, t.rate, " beats")
    )
    params:set_action(pfx .. "rate", function(v)
      tracks[i].rate = v
      start_track(i)
    end)

    params:add_number(pfx .. "vel", "t" .. i .. " vel", 1, 127, t.vel)
    params:set_action(pfx .. "vel", function(v)
      tracks[i].vel = v
    end)

    params:add_control(
      pfx .. "dur",
      "t" .. i .. " dur",
      controlspec.new(0.01, 2.0, "lin", 0.01, t.duration, " s")
    )
    params:set_action(pfx .. "dur", function(v)
      tracks[i].duration = v
    end)

    params:add_number(pfx .. "ch", "t" .. i .. " channel", 1, 16, t.channel)
    params:set_action(pfx .. "ch", function(v)
      tracks[i].channel = v
    end)

  end

end

-- -------------------------------------------------------------------------
-- SCREEN
-- -------------------------------------------------------------------------

function redraw()
  screen.clear()
  screen.aa(0)
  screen.font_size(8)

  screen.level(15)
  screen.move(2, 8)
  screen.text("DRIFT")
  screen.move(60, 8)
  screen.text(string.format("%.0f bpm", clock.get_tempo()))

  for i, t in ipairs(tracks) do
    local y = 16 + (i * 12)
    screen.level(t.active and 12 or 3)
    screen.move(2, y)
    screen.text(string.sub(t.name, 1, 7))
    screen.move(52, y)
    screen.text(string.format("%.2f", t.rate))
    screen.move(90, y)
    screen.text(t.mode == "trigger" and "trig" or "synt")
    screen.move(112, y)
    screen.text(t.channel)
  end

  screen.level(4)
  screen.move(2, 62)
  screen.text((playing and "K2:stop " or "K2:play ") .. "K3:sync")

  screen.update()
end

-- -------------------------------------------------------------------------
-- ENCODERS / KEYS
-- -------------------------------------------------------------------------

function enc(n, delta) end

local playing = true

function key(n, z)
  if z == 1 then
    if n == 2 then
      -- K2: toggle play/stop all tracks
      playing = not playing
      if playing then
        for i = 1, #tracks do
          start_track(i)
        end
      else
        for i = 1, #tracks do
          stop_track(i)
        end
      end
      redraw()
    elseif n == 3 then
      -- K3: resync all tracks to same start point
      for i = 1, #tracks do
        start_track(i)
      end
      redraw()
    end
  end
end

-- -------------------------------------------------------------------------
-- INIT / CLEANUP
-- -------------------------------------------------------------------------

function init()
  setup_params()
  params:read()
  params:bang()

  for i = 1, #tracks do
    note_index[i] = 1
    start_track(i)
  end

  norns.menu_close = function()
    redraw()
  end

  redraw()
  print("drift loaded -- " .. #tracks .. " tracks")
end

function cleanup()
  for i = 1, #tracks do
    stop_track(i)
  end
end
