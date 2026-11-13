method main {
  val a = 2 + 3 * 4
  val b = if a > 10 then 100 else 0
  print("a = $a, b = $b")
  for (i <- 1 -> 5) {
    print(" i=${i}")
  }
  println("")
  for (i in 1 -> 3) {
    println("linea ${i}")
  }
}
