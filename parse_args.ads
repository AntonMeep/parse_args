-- parse_args.ads

-- A simple command line option parser
-- Copyright James Humphry 2014

with Ada.Strings.Unbounded;
use Ada.Strings.Unbounded;

with Ada.Containers;
with Ada.Containers.Indefinite_Hashed_Maps, Ada.Strings.Hash;

package Parse_Args is

   type Argument_Parser is tagged limited private
     with Constant_Indexing => Constant_Reference;

   procedure Parse_Command_Line(A : in out Argument_Parser);
   function Parse_Success(A : in Argument_Parser) return Boolean;
   function Parse_Message(A : in Argument_Parser) return String;
   function Command_Name(A : in Argument_Parser) return String;
   function Boolean_Value(A : in Argument_Parser; Name : in String) return Boolean;
   function Natural_Value(A : in Argument_Parser; Name : in String) return Natural;
   function String_Value(A : in Argument_Parser; Name : in String) return String;

   procedure Add_Boolean_Option(A : in out Argument_Parser;
                                Name : in String;
                                Short_Option : in Character := '-';
                                Default : in Boolean := False;
                                Long_Option : in String := "");

   procedure Add_Repeated_Option(A : in out Argument_Parser;
                                 Name : in String;
                                 Short_Option : in Character := '-';
                                 Default : in Natural := 0;
                                 Long_Option : in String := "");

   procedure Add_Natural_Option(A : in out Argument_Parser;
                                Name : in String;
                                Short_Option : in Character := '-';
                                Default : in Natural := 0;
                                Long_Option : in String := "");

   procedure Add_String_Option(A : in out Argument_Parser;
                                Name : in String;
                                Short_Option : in Character := '-';
                                Default : in String := "";
                                Long_Option : in String := "");

   type Option is abstract tagged limited record
      Set : Boolean := False;
   end record;

   procedure Set_Option(O : in out Option; A : in out Argument_Parser'Class) is abstract;
   procedure Set_Option_Argument(O : in out Option;
                                 Arg : in String;
                                 A : in out Argument_Parser'Class) is null;

   type Option_Ptr is not null access Option'Class;

   function Constant_Reference(C : aliased in Argument_Parser;
                               Name : in String) return Option_Ptr;

   type Option_With_Argument is abstract new Option with null record;
   procedure Set_Option(O : in out Option_With_Argument; A : in out Argument_Parser'Class);

   -- Define interfaces to specify different possible return values

   type Boolean_Option is limited interface;
   function Value(A : in Boolean_Option) return Boolean is abstract;

   type Natural_Option is limited interface;
   function Value(A : in Natural_Option) return Natural is abstract;

   type String_Option is limited interface;
   function Value(A : in String_Option) return String is abstract;

private

   package Option_Maps is new Ada.Containers.Indefinite_Hashed_Maps(Key_Type => String,
                                                                    Element_Type => Option_Ptr,
                                                                    Hash => Ada.Strings.Hash,
                                                                    Equivalent_Keys => "=");

   function Char_Hash(C : in Character) return Ada.Containers.Hash_Type is
     (Ada.Containers.Hash_Type(Character'Pos(C)));

   package Option_Char_Maps is new Ada.Containers.Indefinite_Hashed_Maps(Key_Type => Character,
                                                                    Element_Type => Option_Ptr,
                                                                    Hash => Char_Hash,
                                                                    Equivalent_Keys => "=");

   procedure Add_Option(A : in out Argument_Parser;
                        Name : in String;
                        Short_Option : in Character := '-';
                        Long_Option : in String := "";
                        O : in Option_Ptr);

   type Argument_Parser_State is (Init,
                                  Ready,
                                  Required_Argument,
                                  Positional_Only,
                                  Finish_Success,
                                  Finish_Erroneous);

   type Argument_Parser is tagged limited record
      State : Argument_Parser_State := Init;
      Last_Option : access Option'Class;
      Command_Name : Unbounded_String;
      Arguments : Option_Maps.Map;
      Long_Options : Option_Maps.Map;
      Short_Options : Option_Char_Maps.Map;
      Message : Unbounded_String;
   end record;

   type Concrete_Boolean_Option is new Option and Boolean_Option with record
      Value : Boolean := False;
      Default : Boolean := False;
   end record;
   procedure Set_Option(O : in out Concrete_Boolean_Option; A : in out Argument_Parser'Class);
   function Value(A : in Concrete_Boolean_Option) return Boolean is (A.Value);

   type Repeated_Option is new Option and Natural_Option with record
      Value : Natural := 0;
      Default : Natural := 0;
   end record;
   procedure Set_Option(O : in out Repeated_Option; A : in out Argument_Parser'Class);
   function Value(A : in Repeated_Option) return Natural is (A.Value);

   type Concrete_Natural_Option is new Option_With_Argument and Natural_Option with record
      Value : Natural := 0;
      Default : Natural := 0;
   end record;
   procedure Set_Option_Argument(O : in out Concrete_Natural_Option;
                                 Arg : in String;
                                 A : in out Argument_Parser'Class);
   function Value(A : in Concrete_Natural_Option) return Natural is (A.Value);

   type Concrete_String_Option is new Option_With_Argument and String_Option with record
      Value : Unbounded_String := Null_Unbounded_String;
      Default : Unbounded_String := Null_Unbounded_String;
   end record;
   procedure Set_Option_Argument(O : in out Concrete_String_Option;
                                 Arg : in String;
                                 A : in out Argument_Parser'Class);
   function Value(A : in Concrete_String_Option) return String is (To_String(A.Value));

end Parse_Args;
