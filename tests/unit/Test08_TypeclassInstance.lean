/-
  Test08_TypeclassInstance: Instance used implicitly by TARGET.

  EDGE CASE: A typeclass instance may not appear in explicit syntax
  but is resolved by Lean's instance resolution. The tool must
  recognize implicit usage through the Environment API.

  Live: MyClass, myInstance (used implicitly by TARGET via instance resolution)
  Dead: dead_instance_user (not used by TARGET)

  EXPECTED: dead_instance_user removed. MyClass + myInstance stay.
  ACCEPTANCE: File compiles with dead items removed.
-/

-- A simple typeclass
class MyClass (α : Type) where
  myMethod : α → Nat

-- An instance: live because TARGET uses it implicitly
instance myInstance : MyClass Nat where
  myMethod := fun n => n + 1

-- TARGET: uses myInstance IMPLICITLY via MyClass.myMethod resolution
theorem target : MyClass.myMethod (5 : Nat) = 6 := rfl

-- DEAD: uses the typeclass but TARGET doesn't depend on this
theorem dead_instance_user : MyClass.myMethod (10 : Nat) = 11 := rfl
