object RatingEntry(val name: String, val rating: Integer)
object RatingList(val item: RatingEntry)

method main {
  val a = 10
  val b = 5
  val max = if a > b then a else b
  val ratings = new RatingList(new RatingEntry("Inception", 5))
  for ((name, rating) <- ratings) { print("Movie: $name, Rating: $rating") }
}