import gleam/dynamic
import gleam/dynamic/decode
import gleam/javascript/promise.{type Promise}
import gleam/list
import lustre
import lustre/attribute
import lustre/effect
import lustre/element.{text}
import lustre/element/html.{button, div, p}
import lustre/event.{on_click}
import lustre/vdom/vnode

@external(javascript, "./js/flustre.mjs", "log")
pub fn log(value: a) -> Nil

@external(javascript, "./js/flustre.mjs", "ping")
pub fn do_ping() -> String

@external(javascript, "./js/flustre.mjs", "add_data")
pub fn add_data() -> a

@external(javascript, "./js/flustre.mjs", "getData")
pub fn do_get_data() -> Promise(dynamic.Dynamic)

fn ping() -> effect.Effect(Msg) {
  effect.from(fn(dispatch) {
    do_ping()
    |> DataLoaded
    |> dispatch
  })
}

fn get_data() -> effect.Effect(Msg) {
  effect.from(fn(dispatch) {
    do_get_data()
    |> promise.map(UserDataLoaded)
    |> promise.tap(dispatch)
    Nil
  })
}

pub fn main() -> Nil {
  let app = lustre.application(init, update, view)
  let assert Ok(_) = lustre.start(app, "#app", Nil)
  Nil
}

pub fn init(_flags) -> #(Model, effect.Effect(a)) {
  #(NotLoaded, effect.none())
}

pub type Model {
  NotLoaded
  Loading
  Loaded(String)
  LoadedUser(List(User))
}

pub type Msg {
  Ping
  DataLoaded(String)
  FetchUserData
  UserDataLoaded(dynamic.Dynamic)
}

pub type User {
  User(
    id: Int,
    first_name: String,
    last_name: String,
    email: String,
    gender: String,
    phone: String,
    image: String,
  )
}

fn user_decoder() -> decode.Decoder(User) {
  use id <- decode.field("id", decode.int)
  use first_name <- decode.field("firstname", decode.string)
  use last_name <- decode.field("lastname", decode.string)
  use email <- decode.field("email", decode.string)
  use gender <- decode.field("gender", decode.string)
  use phone <- decode.field("phone", decode.string)
  use image <- decode.field("image", decode.string)
  decode.success(User(id, first_name, last_name, email, gender, phone, image))
}

fn users_decoder() -> decode.Decoder(List(User)) {
  decode.list(user_decoder())
}

fn decoded_user(
  res: dynamic.Dynamic,
) -> Result(List(User), List(decode.DecodeError)) {
  decode.run(res, users_decoder())
}

pub fn update(_model: Model, msg: Msg) -> #(Model, effect.Effect(Msg)) {
  case msg {
    Ping -> {
      #(Loading, ping())
    }
    DataLoaded(data) -> {
      #(Loaded(data), effect.none())
    }
    FetchUserData -> {
      #(Loading, get_data())
    }
    UserDataLoaded(data) -> {
      let decoded_users = decoded_user(data)
      case decoded_users {
        Ok(users) -> {
          #(LoadedUser(users), effect.none())
        }
        Error(_errors) -> {
          #(NotLoaded, effect.none())
        }
      }
    }
  }
}

fn view_user_list(user_list: List(User)) -> vnode.Element(Msg) {
  div(
    [attribute.id("user-list")],
    user_list |> list.map(fn(user) { view_user(user) }),
  )
}

fn view_user(user: User) -> vnode.Element(Msg) {
  p([], [text(user.first_name <> " " <> user.last_name <> " " <> user.email)])
}

pub fn view(model: Model) -> vnode.Element(Msg) {
  div([], [
    p([], [text("Fluffy")]),
    case model {
      NotLoaded ->
        div([], [
          p([], [text("Click the button to ping the server.")]),
          button([on_click(Ping)], [text("Ping")]),
          button([on_click(FetchUserData)], [text("FetchUserData")]),
        ])
      Loaded(data) ->
        div([], [
          p([], [text(data)]),
          button([on_click(Ping)], [text("Ping Again")]),
          button([on_click(FetchUserData)], [text("FetchUserData Again")]),
        ])
      Loading -> div([], [p([], [text("Loading...")])])
      LoadedUser(data) -> {
        //let users = decoded_user(data)
        case data {
          user_list -> {
            div([], [
              p([], [text("User Data Loaded:")]),
              view_user_list(user_list),
              button([on_click(Ping)], [text("Ping")]),
              button([on_click(FetchUserData)], [text("FetchUserData Again")]),
            ])
          }
        }
      }
    },
  ])
}
