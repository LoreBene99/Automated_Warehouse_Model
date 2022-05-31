(define (problem instance4_warehouse)

  (:domain warehouse)

  (:objects
    Mover1 Mover2 - mover
    Crate1 Crate2 Crate3 Crate4 Crate5 Crate6 - crate
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
    (crate_at_shelf Crate5)
    (crate_at_shelf Crate6)

    (= (distance Crate1) 20.0)
    (= (distance Crate2) 20.0)
    (= (distance Crate3) 10.0)
    (= (distance Crate4) 20.0)
    (= (distance Crate5) 30.0)
    (= (distance Crate6) 10.0)

    (= (weight Crate1) 30.0)
    (= (weight Crate2) 20.0)
    (= (weight Crate3) 30.0)
    (= (weight Crate4) 20.0)
    (= (weight Crate5) 30.0)
    (= (weight Crate6) 20.0)

    (is_fragile Crate2)
    (is_fragile Crate3)
    (is_fragile Crate4)
    (is_fragile Crate5)

    (= (loading_time Loader_ex) 0.0)
    (= (loading_time Loader_ch) 0.0)
  )

  (:goal
    (and
      (crate_on_belt Crate1)
      (crate_on_belt Crate2)
      (crate_on_belt Crate3)
      (crate_on_belt Crate4)
      (crate_on_belt Crate5)
      (crate_on_belt Crate6)
      (robot_at_bay Mover1)
      (robot_at_bay Mover2)

    (near_in_sequence Crate1 Crate2)

      (or
        (and
          (near_in_sequence Crate4 Crate3)
          (near_in_sequence Crate3 Crate5)
        )
        (and
          (near_in_sequence Crate3 Crate4)
          (near_in_sequence Crate4 Crate5)
        )
        (and
          (near_in_sequence Crate3 Crate5)
          (near_in_sequence Crate5 Crate4)
        )
      )
    )
  )

  (:metric minimize(total-time))
)