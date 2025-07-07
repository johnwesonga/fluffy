
import { PGlite } from 'https://cdn.jsdelivr.net/npm/@electric-sql/pglite/dist/index.js'
console.log('Staring Pglite...');
// In-memory database:
const pg = new PGlite()
// Or, stored in indexedDB:
// const pg = new PGlite('pgdata');

console.log('Ready!')

console.log('Creating table...')
await pg.exec(`
  CREATE TABLE IF NOT EXISTS  users (
    id SERIAL PRIMARY KEY,
    firstName TEXT,
    lastName TEXT,
    email TEXT,
    gender TEXT,
    phone TEXT,
    image TEXT
  );
`)
add_data()

export async function add_data() {
  console.log('Inserting data...')
  await pg.exec("INSERT INTO  users (firstName, lastName, email, gender, phone, image) VALUES ('john', 'doe', 'john.doe@example.com', 'male', '1234567890', 'https://example.com/john.jpg');")
  await pg.exec("INSERT INTO  users (firstName, lastName, email, gender, phone, image) VALUES ('peter', 'smith', 'peter.smith@example.com', 'male', '1234567890', 'https://example.com/peter.jpg');")
  console.log('Data inserted!')

}
export async function getData() {
  let parsedResult;
  let res = await pg.query(`
    SELECT * FROM users;
  `);
  return res.rows;

}

export async function getData2() {
  fetch('https://dummyjson.com/users')
    .then(res => res.json())
    .then(console.log);
}

export function ping() {
  console.log("ping from JavaScript");
  return "bing bang boom";

}

export function log(value) {
  console.log(value);
}
