# This module allows you to specify pronouns based on the class this module is mixed into.
# This module expects a gender instance variable of "m" or "f"
# Examples: 
# for a male user:
# 
#     * @user.pronoun.subjective = he
#     * @user.pronoun.objective = him
#     * @user.pronoun.reflective = himself
#     * @user.pronoun.possessive = his
#     * @user.pronoun.determiner = his 
# 
# for a female user:
# 
#     * @user.pronoun.subjective = she
#     * @user.pronoun.objective = her
#     * @user.pronoun.reflective = herself
#     * @user.pronoun.possessive = hers
#     * @user.pronoun.determiner = her 
#
# for gender neutral:
#     * @user.pronoun.subjective = they
#     * @user.pronoun.objective = them
#     * @user.pronoun.reflective = themselves
#     * @user.pronoun.possessive = theirs
#     * @user.pronoun.determiner = their

module Pronouner
  def self.included(base)
    def subjective_name
      name = "they"
      name = "he"  if male? 
      name = "she" if female?
      name
    end
    
    def objective_name
      name = "them"
      name = "him"  if male? 
      name = "her" if female?
      name
    end

    def reflective_name
      name = "themselves"
      name = "himself"  if male? 
      name = "herself" if female?
      name
    end
    
    def possessive_name
      name = "theirs"
      name = "his"  if male? 
      name = "hers" if female?
      name
    end

    def determiner_name
      name = "their"
      name = "his"  if male? 
      name = "her" if female?
      name
    end
    
    def male?
      gender == 'm'
    end
    
    def female?
      gender == 'f'
    end
  end
end