(define (problem instance3_warehouse)

  (:domain warehouse)

  (:objects
    Mover1 Mover2 - mover
    Crate1 Crate2 Crate3 Crate4 - crate
    Loader_ex - expensive
    Loader_ch - cheap
  )

  (:init
    (conveyor_is_empty)

    (= (weight_threshold) 50.0)
    (= (loading_threshold) 4.0)
    (= (loading_threshold_fragile) 6.0)

    (robot_at_bay Mover1)
    (robot_at_bay Mover2)

    (= (battery_max) 20.0)
    (= (battery_min) 0.0)
    (= (battery Mover1) 20.0)
    (= (battery Mover2) 20.0)

    (= (travelled Mover1) 0.0)
    (= (travelled Mover2) 0.0)

    (crate_at_shelf Crate1)
    (crate_at_shelf Crate2)
    (crate_at_shelf Crate3)
    (crate_at_shelf Crate4)

    (= (distance Crate1) 20.0)
    (= (distance Crate2) 20.0)
    (= (distance Crate3) 30.0)
    (= (distance Crate4) 10.0)

    (= (weight Crate1) 70.0)
    (= (weight Crate2) 80.0)
    (= (weight Crate3) 60.0)
    (= (weight Crate4) 30.0)

    (is_fragile Crate2)

    (= (loading_time Loader_ex) 0.0)
    (= (loading_time Loader_ch) 0.0)
  )

  (:goal
    (and
      (crate_on_belt Crate1)
      (crate_on_belt Crate2)
      (crate_on_belt Crate3)
      (crate_on_belt Crate4)
      (robot_at_bay Mover1)
      (robot_at_bay Mover2)

      (or
        (and
          (near_in_sequence Crate2 Crate1)
          (near_in_sequence Crate1 Crate3)
        )
        (and
          (near_in_sequence Crate1 Crate2)
          (near_in_sequence Crate2 Crate3)
        )
        (and
          (near_in_sequence Crate1 Crate3)
          (near_in_sequence Crate3 Crate2)
        )
      )
    )
  )
  (:metric minimize(total-time))
)
