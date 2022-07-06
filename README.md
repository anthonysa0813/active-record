# Associaciones ( Active record )

![erd_project](app/assets/images/erd.jpg)

# Creación de modelos

```bash
rails generate model User username email role critics_count:integer
```

```bash
rails generate model Critic title body_text user:references
```

<!-- `````` -->

```bash
rails generate model Company name description:text start_date:date country cover
```

```bash
rails generate model Game name summary:text realease_date:date category:integer rating:decimal cover
```

```bash
rails generate model Platform name category:integer
```

```bash
rails generate Genre name
```

```
rails generate model InvolvedCompany company:references game:references developer:boolean publisher:boolean
```

## Asociaciones Básicas

### User y Critics

```ruby
# user.rb
class User < ApplicationRecord
  has_many :critics
end
# critic.rb
class Critic < ApplicationRecord
  belongs_to :user
end
```

- Un usuario puede hacer muchas criticas (has_many), pero una critica pertenece a un usuario (belongs_to)

### Join table (Game & Platform | Game & Genre)

```bash
 rails generate migration CreateJoinTableGamePlatform game platform
```

```bash
 rails generate migration CreateJoinTableGameGenre game genre
```

- Join table crea uan tabla a nivel de base de datos, pero no es un modelo. solo guardaremos el game_id y platform_id (Game & Platform)

### Muchos a muchos (through)

```ruby

#company.rb
class Company < ApplicationRecord
  has_many :involved_companies, dependent: :destroy
  has_many :games, through: :involved_companies
end

# involved_company.rb
class InvolvedCompany < ApplicationRecord
  belongs_to :company
  belongs_to :game
end

# game.rb
class Game < ApplicationRecord
  has_many :involved_companies, dependent: :destroy
  has_many :games, through: :involved_companies
end

```

### has_and_belongs_to_many

```ruby
# game.rb
class Game < ApplicationRecord
  has_many :involved_companies, dependent: :destroy
  has_many :companies, through: :involved_companies
  has_and_belongs_to_many :platforms
end
# platforms.rb
class Platform < ApplicationRecord
  has_and_belongs_to_many :games
end
```

```bash
 game = Game.first
 playstation = Platform.first
 game.platforms.push(playstation)
```

- Ojo: No podemos usar el verbo create, save, update, etc en este caso, porque creamos la tabla a un nivel de base de datos, más no hemos creado el modelo.

# Self join (parent_id en Game)

1. primero generamos una migración, para generar un referencia hacia la tabla Game

```bash
rails generate migration AddParentRefToGame parent:references
```

2. hacemos la asociación en la migración

```ruby
class AddParentRefToGame < ActiveRecord::Migration[7.0]
  def change
    add_reference :games, :parent, foreign_key: {to_table: :games}
  end
end
```

3. le quitamos el null: false, porque va a ver ocaciones que un juego no va a tener una expansión, entonces debe de recibir campos nulos. Por último, debemos que decirle hacia que modelo va a apuntar. foreign_key: {to_table: :games}

```ruby
# game.rb
class Game < ApplicationRecord
  has_many :expansions, class_name: "Game",
                        foreign_key: "parent_id",
                        dependent: :destroy,
                        inverse_of: "parent"
  belongs_to :parent, class_name: "Game", optional: true
end
```

4. En este último paso, le estamos asociando que un Game puede tener "expansiones" a través de la clase Game, y su llave foranea será el "parent_id".
5. Pero también un juego (expansion) va a tener un parent (juego principal), a través de la misma tabla de modelo Game.

```bash
  gta = Game.first
  gta_exp = Game.create!(name:"gta expansion 1", parent_id: gta.id)
  # esto dará información de quien es su padre (main Game)
  gta_exp.parent
  # esto nos dará todos los juegos que son expansiones
  gta.expansions
```

# Polymorphic

1. Para este caso, tenemos que el modelo o campo de critics, puede tiene el mismo cuerpo tanto como para una compañia y juego (company & game).En este caso, para no crear dos tablas critics_game y critics_company, usamos el polimorfismo, solo creamos una única tabla y le decimos hacia que modelo de tabala va a apuntar ya sea a (company | game).
2. El polimoformismo va a agregar dos campos a nuestra tabla de critics

- criticable_type
- criticable_id

3. Para decirle que nuestra tabla va a tener un campo polimorfico, debemos que de crear una migración

```bash
rails generate migration AddCriticableToCritics criticable:references{polymorphic}
```

```ruby
# migration table
class AddCriticableToCritics < ActiveRecord::Migration[7.0]
  def change
    add_reference :critics, :criticable, polymorphic: true, null: false
  end
end
```

# asociación polymorphic

```ruby
class Critic < ApplicationRecord
  belongs_to :user
  belongs_to :criticable, polymorphic: true
end
```

1. En este primer punto, debemos de decirle a nuestro modelo de critic que va a pertenecer a un campo "criticable" y este se va a comportar de manera polymorphica

```ruby
class Company < ApplicationRecord
  has_many :involved_companies, dependent: :destroy
  has_many :games, through: :involved_companies
  has_many :critics, as: :criticable
end
```

2. Nuestro modelo de company, va a tener muchas critics pero como criticable

```ruby
class Game < ApplicationRecord
  has_many :critics, as: :criticable
end
```

## para crear una critica

1. debemos de crear un user, company y un juego

```bash
# critica a un juego (gta)
Critic.create!(title:"Mi critica al juego de gta", user_id: us
er.id, criticable:gta)
```

# Enums

```ruby
class Game < ApplicationRecord
  enum :category, { main_game: 0, expansion: 1 }
end
```

1. Con enum, vamos a decir que cierto campo de nuestro modelo, em este caso :category, va aceptar valores enteros y que estos enteros va a representar un valor distinto, si es 0 va a ser un main_game, si es 1 va ser expansion.

2. Pero antes de ingresar un dato, vamos a definit un valor por default, que nuestros juegos si no le pasamos un valor en category, que venga por default en 0 (main_game).
3. rails g migration AddDefaultCategoryToGames

```ruby
class AddDefaultCategoryToGame < ActiveRecord::Migration[7.0]
  def change
    change_column_default(:games, :category, from: nil, to: 0)
  end
end
```

```bash
Game.create!(name:"Mario bros", category: 0)
```

# counter_caché

1. Este counter_caché es un sumatorio, en terminos simples, es un método que recibe nuestro modelo critic con relación a la asociación que le pertece, este irá a buscar un campo llamado something_count y le sumará +1 al crearse una crítica.

```ruby
class Critic < ApplicationRecord
  belongs_to :user, counter_cache: true
  belongs_to :criticable, polymorphic: true
end
```

# Validaciones

### Critic:

- title, body: required
- title: max 40 characters

```ruby
class Critic < ApplicationRecord
  validates :body, presence: true
  validates :title, presence: true, length: { maximum: 40 }
end
```

### Game:

- name, category: required
- name: unique
- rating: between 0 and 100 (if provided)
- parent_id: if the category is expansion, parent_id should be a valid game_id. If a category is main_game, parent_id should be null.

```bash
rails generate migration AddIndexToGame name:string:uniq
```

```ruby
class AddIndexToGame < ActiveRecord::Migration[7.0]
  def change
    add_index :games, :name, unique: true
  end
end
```

```ruby
class Game < ApplicationRecord
  validates :name, :category, presence: true
  validates :name, uniqueness: true
  validates :rating, comparison: { greater_than_or_equal_to: 0,
                                  less_than_or_equal_to: 100,
                                  allow_nil: true
                                  }
  validate :validate_parent

  # has_many :involved_companies, dependent: :destroy
  # has_many :companies, through: :involved_companies
  # has_and_belongs_to_many :platforms
  # has_many :expansions, class_name: "Game",
  #                       foreign_key: "parent_id",
  #                       dependent: :destroy,
  #                       inverse_of: "parent"
  # belongs_to :parent, class_name: "Game", optional: true
  # has_many :critics, as: :criticable, dependent: :destroy
  # enum :category, { main_game: 0, expansion: 1 }

  private

  def validate_parent
    if category == "main_game" && parent_id
      errors.add(:parent_id, "Should be null")
    elsif category == "expansion" && Game.find_by(id: parent_id).nil?
      errors.add(:parent_id, "Should be a valid game id")
    end
  end
end

```

### User

- username, email: required and unique
- birth_date: before 16 years from now. Message: You should be 16 years old to create an account (this one requires custom validations)

```bash
rails generate migration AddIndexUsernameEmailToUser username:string:uniq email:string:uniq
```

1. Si piden que sea único debemos de realizar una migración para cambiar el valor a un indice único en la columna de la DB.

```ruby
# migración
class AddIndexUsernameEmailToUser < ActiveRecord::Migration[7.0]
  def change
    add_index :users, :username, unique: true
    add_index :users, :email, unique: true
  end
end
```

# Ojo: Para agregar una columna

```bash
rails generate migration AddBirthDateToUser birth_date:date
```

```ruby
class User < ApplicationRecord
  validates :username, :email, presence: true, uniqueness: true
  validate :sixteen_or_older
  has_many :critics, dependent: :destroy

  private
  def sixteen_or_older
    return if birth_date >= 16.years.ago

    errors.add(:birth_date, "You should be 16 years old to create an account")
  end
end

```

### Platform:

- name, category: required
- name: unique

```bash
rails generate migration AddNameUniqueToPlatform name:string:uniq
```

```ruby
class Platform < ApplicationRecord
  validates :name, :category, presence: true
  validates :name, uniqueness: true


  has_and_belongs_to_many :games
  enum :category, { console: 0, arcade: 1, platform: 2, operating_system: 3, portable_console: 4, computer: 5 }
end
```

### Genre:

- name: required and unique

```bash
rails generate migration AddIndexNameToGenre name:string:uniq
```

```ruby
# migration
class AddIndexNameToGenre < ActiveRecord::Migration[7.0]
  def change
    add_index :genres, :name, unique: true
  end
end
# genre.rb
class Genre < ApplicationRecord
  validates :name, presence: true, uniqueness: true
end
```

### Company:

name: required and unique

```bash
rails generate migration AddIndexNameToCompany name:string:uniq
```

```ruby
# migration
class AddIndexNameToCompany < ActiveRecord::Migration[7.0]
  def change
    add_index :companies, :name, unique: true
  end
end
# company.rb
class Company < ApplicationRecord
  validates :name, presence: true, uniqueness: true
end
```

### InvolvedCompany:

- developer, publisher: required
- company_id and game_id should be a unique combination

```ruby
class InvolvedCompany < ApplicationRecord
  validates :developer, :publisher, inclusion: { in: [true, false]}
  # no lo podemos hacer presence: true, ya que en el caso de poner un valor que de falso, esto dará un error y lo tomará como blank
  validates :company, uniqueness: { scope: :game, message: "and Game combination alredy taken"}
  # podemos juntar validaciones con el scope

  belongs_to :company
  belongs_to :game
end
```

```bash
rails g migration AddIndexCompanyGameToInvolvedCompany
```

```ruby
class AddIndexCompanyGameToInvolvedCompany < ActiveRecord::Migration[7.0]
  def change
    add_index :involved_companies, [:game_id, :company_id] , unique: true
  end
end
```
