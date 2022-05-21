import gg
import gx
import time
import miniaudio as ma

struct DrumSound {
	kick int = 0
	snare int = 1
	hihat int = 2
}

struct AppState {
	mut:
		gg &gg.Context = 0
		board [][]bool = [][]bool{len: 3, cap: 3, init: []bool{len: 16, cap: 16, init: false}}
		mx f32
		my f32
		mdown bool
		mmode bool

		keys string
		box []int

    kick ma.Sound
    hat ma.Sound
    snare ma.Sound

		playing bool = false
		last_step i64 = 0
		step int = 0
		until_next_step i64 = 0
		bpm int = 60
		current_step_played bool = true
		just_started bool = false
}

fn main() {
	mut	state := &AppState{}
	state.gg = gg.new_context(
		bg_color: gx.rgb(100, 100, 0)
		width: 540
		height: 150
		resizable: false
		window_title: 'Sequencer'
		frame_fn: frame
		move_fn: move
		keydown_fn: key
		click_fn: click
		unclick_fn: unclick
		quit_fn: quit
		user_data: state
	)
	mut d := ma.device()
	
	state.hat = ma.sound('/Users/danieldb/Desktop/terca/hat.wav')
	state.kick = ma.sound('/Users/danieldb/Desktop/terca/kick.wav')
	state.snare = ma.sound('/Users/danieldb/Desktop/terca/snare.wav')

	d.add('kick', state.kick)
	d.add('snare', state.snare)
	d.add('hat', state.hat)

	state.snare.play()
	time.sleep(state.snare.length() * time.millisecond)
	state.gg.run()
}
fn frame(mut state AppState){
	if state.playing {
		if !state.current_step_played{
			state.current_step_played = true
			if state.board[0][state.step] {
				play_drum_sound(0, mut state)
			}
			if state.board[1][state.step] {
				play_drum_sound(1, mut state)
			}
			if state.board[2][state.step] {
				play_drum_sound(2, mut state)
			}
		}
		state.until_next_step = 1000*(60 / state.bpm)/4 - (time.ticks() - state.last_step)
		//println(state.until_next_step)
		// (seconds per beat) - (time)
		if state.until_next_step <= 0 || state.just_started {
			state.step = (state.step + 1) % 16
			if state.just_started { state.step = 0 }
			state.until_next_step = 60 / state.bpm
			state.last_step = time.ticks()
			state.current_step_played = false
			state.just_started = false
		}
	}
	
	start := [30, 30, 30, 30]
	ctx := state.gg
	mut mouse_in_box := false
	ctx.begin()

	for iy, row  in state.board {
		for ix, step in row{
			ctx.draw_rect_empty(start[0] + ix*start[2], start[1] + iy*start[3], start[2], start[3], gx.rgb(0, 0, 0))
			
			if state.playing && ix == state.step {
				ctx.draw_rect_filled(start[0] + ix*start[2], start[1] + iy*start[3], start[2], start[3], gx.rgba(255, 255, 255, 70))
			}

			if step {
				ctx.draw_circle_filled(start[0] + ix*start[2] + start[2]/2, start[1] + iy*start[3] + start[3]/2, start[2]/4, gx.rgb(255, 255, 255))
			}

			if state.mx > start[0] + ix*start[2] && state.mx < start[0] + ix*start[2] + start[2] && state.my > start[1] + iy*start[3] && state.my < start[1] + iy*start[3] + start[3] {
				ctx.draw_rect_filled(start[0] + ix*start[2], start[1] + iy*start[3], start[2], start[3], gx.rgba(255, 255, 255, 32))
				state.box = [ix, iy]
				mouse_in_box = true
			}else if !mouse_in_box {
				state.box = [-1, -1]
			}
		}
	} 

	ctx.end()
}

fn move(x f32, y f32, mut state AppState){
	state.mx = x
	state.my = y
	
	if state.mdown {
		if state.mmode {
			if state.box[0] != -1 && state.box[1] != -1 {
				state.board[state.box[1]][state.box[0]] = true
			}
		}else{
			if state.box[0] != -1 && state.box[1] != -1 {
				state.board[state.box[1]][state.box[0]] = false
			}
		}
	}
}

fn click(x f32, y f32, btn gg.MouseButton, mut state AppState){
		//println(state.box)
		state.mdown = true
		if state.box == [-1, -1] { return }
		state.mmode = !state.board[state.box[1]][state.box[0]]
		state.board[state.box[1]][state.box[0]] = !state.board[state.box[1]][state.box[0]]
		play_drum_sound(state.box[1], mut state)
}
fn unclick(x f32, y f32, btn gg.MouseButton, mut state AppState){
		state.mdown = false
}

fn key(key gg.KeyCode, mod gg.Modifier, mut state AppState){
	if key == gg.KeyCode.space {
		if !state.playing {
			state.just_started = true
		}
		state.playing = !state.playing
	}
}

fn play_drum_sound(sound int, mut state AppState){
	if sound == 0{
		state.kick.play()
		state.kick.seek(0)
	}else if sound == 1{
		state.snare.play()
		state.snare.seek(0)
	}else if sound == 2{
		state.hat.play()
		state.hat.seek(0)
	}
}

fn quit(ev &gg.Event, mut state AppState){
}