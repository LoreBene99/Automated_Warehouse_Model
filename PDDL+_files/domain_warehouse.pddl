; This is the domain defined for the first assignment of the AIRO2 course;
; our task is to model an automated warehouse using the specification given by the professor.

(define (domain warehouse)

    ; Typing allows us to create basic and subtypes to which we can apply predicates.
    ; We use types to restrict what objects can form the parameters of an action.
    ; Types and subtypes allow us to declare both general and specific actions and predicates.
    (:types 
        expensive cheap - loader ; Type to differentiate between expensive loader (which can load both heavy and light crates) and cheap loader (which can load only light crates).
        mover - robot ; Type to define mover robots needed to move the crates from the shelf to the loading bay.
        crate - object ; Type to define the crates which will be moved from the shelf to the loading bay by the mover and loaded on the conveyor belt by the loader
    )

    ; Predicates apply to a specific type of object, or to all objects.
    ; Predicates are either true or false at any point in a plan, and when not declared are assumed to be false (except when the Open World Assumption is included as a requirement)
    (:predicates
        (crate_at_shelf ?c - crate) ; Predicate to indicate if the crate is at the shelf.
        (crate_at_bay ?c - crate) ; Predicate to indicate if the crate is at the loading bay.
        (crate_on_belt ?c - crate) ; Predicate to indicate if the crate is on the conveyor belt.
        (is_fragile ?c - crate) ; Predicate to differentiate between fragile and not fragile crates.
        (crate_on_mover ?c - crate ?m - mover) ; Predicate used to know if a crate is being carried by a mover.
        (crate_picked_from_loader ?c - crate ?l - loader) ; Predicate to indicate if a crate has been picked by the loader.
        (crate_placement ?c - crate) ; Predicate needed because some crates have to be grouped on the conveyor belt.
        (last_of_sequence ?c - crate) ; Predicate to define the last crate of a group.
        (near_in_sequence ?cn ?cl - crate) ; Predicate to know if two crates are near in a group.

        (robot_at_bay ?m - mover) ; Predicate to indicate if the mover is at the loading bay.
        (robot_reaching_crate ?m - mover ?c - crate) ; Predicate to know if the mover is moving to a crate.
        (robot_at_crate ?m - mover ?c - crate) ; Predicate to know if the crate has been reached by the mover.
        (robot_waiting ?m - mover) ; Predicate that indicate if the mover is waiting for the loading bay to be free.
        (moving_to_shelf ?m - mover) ; Predicate that indicate if the mover is moving to the shelf.
        (moving_to_conveyor ?m - mover) ; Predicate that indicate if the mover is moving to the loading area.
        (moving_fast_to_conveyor ?m - mover) ; This predicate has been declared since if two movers carry a light crate together they need less time to cover the same distance.
        (robot_coupled ?m - mover) ; Predicate to know if two movers are coupled (in order to move a heavy crate or a light one faster).

        (is_picking ?l - loader) ; Predicate to know if the loader is picking a crate.
        (bay_is_full) ; Predicate to know if the loading bay is full.
        (conveyor_is_empty) ; Predicate to know if the conveyor belt is empty.
    )

    ; In PDDL, predicates are used to encode Boolean state variables, while functions are used to encode numeric state variables.
    (:functions
        (weight ?c - crate) ; Function to define the weight of a crate.
        (distance ?c - crate) ; Function to define the distance of a crate from the loading bay.

        (travelled ?m - mover) ; Function to keep track of the distance covered by the mover.
        (battery ?m - mover) ; Function for the battery of the mover robot.
        (battery_max) ; Threshold for the maximum battery level.
        (battery_min) ; Treshold for the minimum battery level.

        (loading_time ?l - loader) ; Function to indicate the time needed by a loader to load a crate on the belt.

        (weight_threshold) ; Threshold to distinguish between heavy and light crates.
        (loading_threshold) ; Threshold that represent the time taken by the loader to load a crate.
        (loading_threshold_fragile) ; Threshold that represent the time taken by the loader to load a fragile crate.
    )
    ; This action is activated when a new order is placed, it activates the process to move the robot to the shelf.
    ; It requires the robot to be located at the loading bay and the crate to be at the shelf; as effect it tells that the robot is moving to the crate.
    (:action new_order
        :parameters (?m - mover ?c - crate)
        :precondition (and
                (crate_at_shelf ?c)
                (robot_at_bay ?m) 
            )
        :effect (and
            (moving_to_shelf ?m)
            (robot_reaching_crate ?m ?c)
            (not (robot_at_bay ?m))
        )
    ) ;ordinato

    ; This process is used to move the robot from the loading bay to the shelf. It requires a minimum amount of battery to take place and 
    ; as effects it increases the distance travelled by the mover and decreases his battery.
    (:process move_to_shelf
        :parameters (?m - mover)
        :precondition (and 
            (moving_to_shelf ?m)
            (> (battery ?m) (battery_min))
        )
        :effect (and
            (increase (travelled ?m) (* #t 10.0))
            (decrease (battery ?m) (#t))
        )
    )

    ; This event is activated every time that a mover has reached a crate on the shelf. It requires that the distance travelled by the robot is greater or equal to the distance
    ; of the crate from the loading bay, so it can be activated only after the process move_to_shelf. As effects it tells that the robot has reached the crate,
    ; and assign 0 to the distance travelled by the mover.
    (:event reached_crate
        :parameters (?m - mover ?c - crate)
        :precondition (and
            (>=  (travelled ?m) (distance ?c))
            (robot_reaching_crate ?m ?c)
            (moving_to_shelf ?m) 
        )
        :effect (and
            (not (moving_to_shelf ?m))
            (not (robot_reaching_crate ?m ?c))
            (robot_at_crate ?m ?c)
            (assign (travelled ?m) 0)
        )
    ) ;ordinato

   ; This is the action to carry a light crate with a single mover. To take place the robot has to be in the same location of the crate,
   ; the weight of the crate must be lower of the weight threshold. 
   (:action carry1_standard
       :parameters (?m - mover ?c - crate)
       :precondition (and 
            (robot_at_crate ?m ?c)
            (< (weight ?c) (weight_threshold))
            (not (is_fragile ?c))
            (crate_at_shelf ?c)        
       )
       :effect (and
           (moving_to_conveyor ?m)
           (crate_on_mover ?c ?m)
           (not (robot_at_crate ?m ?c))
           (not (crate_at_shelf ?c))
       )
   );ordinato
    

   ; This is the action to carry a heavy crate or to carry a fragile crate, to do so we need two mover robot. It requires also that both the 
   ; robots are at the same location of the crate. As results the two robots are coupled and  they are moving to the loaading area.
   (:action carry2_standard
       :parameters (?m1 ?m2 - mover ?c - crate)
       :precondition (and 
           (robot_at_crate ?m1 ?c)
           (robot_at_crate ?m2 ?c)
           (or
               (>= (weight ?c) (weight_threshold))
               (is_fragile ?c)
           )
           (crate_at_shelf ?c)
           (not (= ?m1 ?m2))
       )
       :effect (and
           (moving_to_conveyor ?m1)
           (moving_to_conveyor ?m2)
           (crate_on_mover ?c ?m1)
           (crate_on_mover ?c ?m2)
           (robot_coupled ?m1)
           (robot_coupled ?m2)
           (not (robot_at_crate ?m1 ?c))
           (not (robot_at_crate ?m2 ?c))
           (not (crate_at_shelf ?c))
       ) 
   ) ;ordinato

    ; This is the action to carry a light crate with two movers. The structure is the same of the action seen before but in this case we check if the weight
    ; of the robot is under the threshold
    (:action carry2_fast
        :parameters (?m1 ?m2 - mover ?c - crate)
        :precondition (and 
            (robot_at_crate ?m1 ?c)
            (robot_at_crate ?m2 ?c)
            (< (weight ?c) (weight_threshold))
            (not (is_fragile ?c))
            (crate_at_shelf ?c)
            (not (= ?m1 ?m2))
        )
        :effect (and
            (moving_fast_to_conveyor ?m1)
            (moving_fast_to_conveyor ?m2)
            (crate_on_mover ?c ?m1)
            (crate_on_mover ?c ?m2)
            (robot_coupled ?m1)
            (robot_coupled ?m2)
            (not (robot_at_crate ?m1 ?c))
            (not (robot_at_crate ?m2 ?c))
            (not (crate_at_shelf ?c))
        )
    ) ;ordinato

    ; This is the process to move the mover that is carrying a crate to the loading bay, it is activated thanks to the actions carry1_standard and carry2_standard.
    ; It requires that the battery of the robot is larger than battery_min and as effects it increases the distance travelled by the robot and decreases its battery. 
    (:process move
        :parameters (?m - mover ?c - crate)
        :precondition (and
            (moving_to_conveyor ?m)
            (crate_on_mover ?c ?m)
            (> (battery ?m) (battery_min))
        )
        :effect (and
            (increase (travelled ?m) (* #t (/ 100.0 (weight ?c))))
            (decrease (battery ?m) (#t))
        )
    )

    ; This is the process to move fast the mover that is carrying a crate to the loading bay, it is activated thanks to the action carry2_fast.
    ; It requires that the battery of the robot is larger than battery_min and as effects it increases the distance travelled by the robot and decreases its battery.
    (:process move2_fast
        :parameters (?m - mover ?c - crate)
        :precondition (and
            (crate_on_mover ?c ?m)
            (moving_fast_to_conveyor ?m)
            (> (battery ?m) (battery_min))
        )
        :effect (and 
            (increase (travelled ?m) (* #t (/ 150.0 (weight ?c))))
            (decrease (battery ?m) (#t))
        )
    )

    ; This event is used to report if the loading bay is full, so it's not possible to put a crate in this location and the robot goes in "waiting state". 
    ; It requires that a crate is on the mover, that the distance travelled by the robot is greater or equal to the distance of the crate from the loading bay.
    ; As said the effect is to put the robot in the "waiting state".
    (:event busy_bay
        :parameters (?m - mover ?c - crate)
        :precondition (and
            (crate_on_mover ?c ?m)
            (>=  (travelled ?m) (distance ?c))
            (bay_is_full)
            (or (moving_to_conveyor ?m)
                (moving_fast_to_conveyor ?m)
            )
        )
        :effect (and
            (robot_waiting ?m)
            (not (moving_to_conveyor ?m))
            (not (moving_fast_to_conveyor ?m))
            (assign (travelled ?m) 0)
        )
    ) ;ordinato

    ; This is the event to unload a crate from a mover. It requires that a crate is on the mover, that the distance travelled by the robot is greater or equal
    ; to the distance of the crate from the loading bay and that the bay is free. As effects the crate will be in the loading bay, the bay will be full and both the robot and the crate
    ; will be at the loading bay
    (:event put_down
        :parameters (?m - mover ?c - crate)
        :precondition (and
            (crate_on_mover ?c ?m)
            (>=  (travelled ?m) (distance ?c))
            (not (bay_is_full))
            (not (robot_coupled ?m))
            (moving_to_conveyor ?m)
        )
        :effect (and
            (crate_at_bay ?c)
            (not (moving_to_conveyor ?m))
            (not (crate_on_mover ?c ?m))
            (bay_is_full)
            (robot_at_bay ?m)
            (assign (travelled ?m) 0.0)
        )
    ) ;ordinato

    ; This is the event to unload a crate which has been carried by two movers. the preconditions are the same as the previous action except for the predicate robot_coupled.
    ; Also the effect of this action is the same as before. 
    (:event put_down_2
        :parameters (?m1 ?m2 - mover ?c - crate)
        :precondition (and
            (crate_on_mover ?c ?m1)
            (crate_on_mover ?c ?m2)
            (>=  (travelled ?m1) (distance ?c))
            (>=  (travelled ?m2) (distance ?c))
            (or 
                (and 
                    (moving_to_conveyor ?m1)
                    (moving_to_conveyor ?m2)
                )
                (and
                    (moving_fast_to_conveyor ?m1)
                    (moving_fast_to_conveyor ?m2)
                )
            )
            (robot_coupled ?m1)
            (robot_coupled ?m2)
            (not (bay_is_full))
            (not (= ?m1 ?m2))
        )
        :effect (and
            (crate_at_bay ?c)
            (not (robot_coupled ?m1))
            (not (robot_coupled ?m2))
            (not (moving_to_conveyor ?m1))
            (not (moving_fast_to_conveyor ?m1))
            (not (moving_to_conveyor ?m2))
            (not (moving_fast_to_conveyor ?m2))
            (not (crate_on_mover ?c ?m1))
            (not (crate_on_mover ?c ?m2))
            (bay_is_full)
            (robot_at_bay ?m1)
            (robot_at_bay ?m2)
            (assign (travelled ?m1) 0.0)
            (assign (travelled ?m2) 0.0)
        )
    ) ;ordinato
    
    ; This is the process to put the robot loaded with a crate in the "waiting state" if the loading bay is full.
    (:process wait
        :parameters (?m - mover)
        :precondition (robot_waiting ?m)
        :effect ()
    )

    ; This event is used to exit from the "waiting state" if the loading bay is no longer full. It requires that the robot is in "waiting state",  that the crate is on
    ; the mover and that the loading bay is not full. The effects are: the robot is no more in the "waiting state" (it is at the loading bay) and the crate is at the loading bay. 
    (:event stop_waiting
        :parameters (?m - mover ?c - crate)
        :precondition (and
            (robot_waiting ?m)
            (crate_on_mover ?c ?m)
            (not (bay_is_full))
            (not (robot_coupled ?m))
        )
        :effect (and
            (not (robot_waiting ?m))
            (crate_at_bay ?c)
            (not (crate_on_mover ?c ?m))
            (bay_is_full)
            (robot_at_bay ?m)
        )
    ) ;ordinato

    ; This event is the same as the previous one. The only difference is that it is used when two movers are carrying the same crate. 
    (:event stop_waiting_2
        :parameters (?m1 ?m2 - mover ?c - crate)
        :precondition (and
            (robot_waiting ?m1)
            (robot_waiting ?m2)
            (crate_on_mover ?c ?m1)
            (crate_on_mover ?c ?m2)
            (not (bay_is_full))
            (robot_coupled ?m1)
            (robot_coupled ?m2)
            (not (= ?m1 ?m2))
        )
        :effect (and
            (not (robot_waiting ?m1))
            (not (robot_waiting ?m2))
            (crate_at_bay ?c)
            (not (crate_on_mover ?c ?m1))
            (not (crate_on_mover ?c ?m2))
            (bay_is_full)
            (robot_at_bay ?m1)
            (robot_at_bay ?m2)
            (not (robot_coupled ?m1))
            (not (robot_coupled ?m2))

        )
    ) ;ordinato

    ; This process is related to the recharging of the robot. It is needed to recharge the robot every time it is at the loading bay. Of course the robot must be at the loading bay and 
    ; its battery must be equal or less than the battery_max value. The only effect of this process is to increase the battery level.
    (:process recharging
        :parameters (?m - mover)
        :precondition (and
            (robot_at_bay ?m)
            (<= (battery ?m) (battery_max))
        )
        :effect (increase (battery ?m) (#t))
    )

    ; This action refers to the loading part. There are two loaders in the environment, the cheaper and expensive one. pick_up_expensive refers to the expensive loader, that can load on the 
    ; conveyor belt any type of crate (heavy or light). It requires the presence of the crate at the loading bay and that the loader is not picking up anything. As consequences the loader is picking up the crate
    ; and the loading bay is not full.
    (:action pick_up_expensive
        :parameters (?l - expensive ?c - crate)
        :precondition (and
            (crate_at_bay ?c)
            (not (is_picking ?l))
            (bay_is_full)
        )
        :effect (and
            (is_picking ?l)
            (crate_picked_from_loader ?c ?l)
            (not (bay_is_full))
            (not (crate_at_bay ?c))
        )
    ) ;ordinato

    ; This action is similar to the previous one, but is related to the cheaper loader; this loader can only pick up light crates which weight is lower than the weight threshold. 
    (:action pick_up_cheap
        :parameters (?l - cheap ?c - crate)
        :precondition (and
            (crate_at_bay ?c)
            (not (is_picking ?l))
            (bay_is_full)
            (< (weight ?c) (weight_threshold)) 
        )
        :effect (and
            (is_picking ?l)
            (crate_picked_from_loader ?c ?l)
            (not (bay_is_full))
            (not (crate_at_bay ?c))
        )
    ) ;ordinato

    ; This is the process that manages the loading of the crate made by the loader. Of course as precondition the loader has to pick up the crate; the only effect regards the increasing of the
    ; loading time value. 
    (:process loading
        :parameters (?l - loader)
        :precondition (is_picking ?l)
        :effect (increase (loading_time ?l) (#t))
    )

    ; This event is needed to stop the loading process; in fact, at this stage, the crate has been put on the conveyor belt. The most important requirement is that the loader is picking up the crate from the 
    ; loading bay. The main effects are: the crate is on the conveyor belt and the loader is not picking up any crate. 
    (:event put_on_belt
        :parameters (?l - loader ?c - crate)
        :precondition (and
            (>= (loading_time ?l) (loading_threshold))
            (is_picking ?l)
            (crate_picked_from_loader ?c ?l)
            (not (is_fragile ?c))
        )
        :effect (and
            (crate_on_belt ?c)
            (not (is_picking ?l))
            (not (crate_picked_from_loader ?c ?l))
            (crate_placement ?c)
            (assign (loading_time ?l) 0.0)
        )
    )

    ; This event is exactly the same of the previous one, except that it is related to the fragile crates. It refers to the crates which are fragile that has been put on the conveyor belt
    ; by the loader.
    (:event put_carefully_on_belt
        :parameters (?l - loader ?c - crate)
        :precondition (and
            (>= (loading_time ?l) (loading_threshold_fragile))
            (is_fragile ?c)
            (is_picking ?l)
            (crate_picked_from_loader ?c ?l)
        )
        :effect (and
            (crate_on_belt ?c)
            (not (is_picking ?l))
            (not (crate_picked_from_loader ?c ?l))
            (crate_placement ?c)
            (assign (loading_time ?l) 0.0)
        )
    )

    ; This event was made up in order to group crates. It refers to the crate that is put on the conveyor belt for the first time (until that moment the conveyor belt is empty). It requires two
    ; important preconditions: the conveyor belt must be empty and the crate_placement predicate must be true, a condition that is verified as a consequence of the put_on_belt/put_carefully_on_belt 
    ; event. As principal effects the crate put on the conveyor belt becomes the last one, therefore the conveyor belt is no more empty.
    (:event first_of_sequence
        :parameters (?c - crate)
        :precondition (and
            (conveyor_is_empty)
            (crate_placement ?c)
        )
        :effect (and
            (last_of_sequence ?c)
            (not (conveyor_is_empty))
            (not (crate_placement ?c))
        )
    )

    ; This event is strictly related to the first_of_sequence event. It refers to the next crate that has been put on the conveyor belt. As the previous event this was made up to group crates.
    ; It mostly requires that the conveyor belt is not full. The principal effect is that the crates put on the conveyor belt are marked as "near in sequence".

    (:event next_of_sequence
        :parameters (?cl ?cn - crate)
        :precondition (and
            (crate_placement ?cn)
            (last_of_sequence ?cl)
            (not (conveyor_is_empty))
        )
        :effect (and
            (near_in_sequence ?cl ?cn)
            (near_in_sequence ?cn ?cl)
            (not (last_of_sequence ?cl))
            (not (crate_placement ?cn))
            (last_of_sequence ?cn)
        )
    )
)
