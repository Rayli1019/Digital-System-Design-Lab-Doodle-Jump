# Doodle Jump
## 數位系統設計實習 期末 Project

[Watch the demo on YouTube](https://www.youtube.com/watch?v=8xgZvJDDkOo)

### How to play?
<img src="/image/image2.png" width="200" align="right">

1. The character in the game will keep jumping up and down.
3. The player must use the left and right arrow keys while jumping with the space bar to let the character jump onto the next platform.  
4. Platforms that flash are one-time use only. They will disappear after being stepped on once. Stable platforms without flashing won’t disappear, and some platforms can also move left and right.  
5. The chance of flashing platforms appearing increases as the score goes up.
<br>
<br>

### Control Panel
<br>
<p align="center"><img src="/image/image1.png" width="585" height="600"></p>  


### Finite State Machine Chart
<img src="/image/image3.png" width="250" align="right">

```
case(state)
           S_IDLE: begin
               if(start == 1) begin
                   next_state = S_INITIAL_GAME;
               end
               else begin
                   next_state = S_IDLE;
               end
           end
           S_INITIAL_GAME: begin
               next_state = S_MOVE;
           end
           S_GENERATE: begin
               if(generate_fg != 0) begin
                   next_state = S_GENERATE;
               end
               else begin
                   next_state = S_MOVE;
               end
           end
           S_MOVE: begin
               next_state = S_MOVE_2;
           end
           S_MOVE_2: begin
               if(end_game == 1) begin
                   state = S_RST;
                   next_state = S_IDLE;
               end
               else if(move_finish == 1) begin
                   next_state = S_NEW_STAIR;
               end
               else begin
                   next_state = S_MOVE;
               end
           end
           S_NEW_STAIR: begin      
               next_state = S_GENERATE;
           end
       endcase
```

### Learning from the project

When actually making the game, I realized that there are many details in the code, such as when to use '<=' versus '=', and I spent a long time debugging. Many times, after finishing the code, I thought it would execute perfectly in my head, but when programming it onto the board, I found that it worked completely differently from what I expected. Since I used FSM, sometimes it would transition into the wrong state at the wrong time, or the output signal wouldn’t be read correctly. I spent a lot of time tracking down these problems, and in the end, I used ModelSim to uncover those hidden bugs.

After actually making the game, I gained a much deeper understanding of FSM, and I even drew FSM charts myself. Before this, during my internship, I only had a vague idea of how it worked and thought having waveforms was enough. It wasn’t until I built something myself that I really understood the intricacies inside.

