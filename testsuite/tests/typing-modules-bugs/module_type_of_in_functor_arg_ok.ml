(* TEST
 expect;
*)

(* Regression test: when [module type of M] is used directly as a
   functor parameter, the resulting signature must keep abstract types
   abstract — even when [M] is reached through a module alias.

   Before the fix, paths going through an alias triggered strengthening
   (via [scrape_for_type_of] following [Mty_alias]), giving the
   parameter a signature like [sig type t = Content.F.t end].  That
   prevented applying the functor to a sibling like [Content.D] whose
   abstract [t] is a different type.

   Module ascriptions [module M : module type of N] keep strengthening,
   matching the behaviour documented by [gatien_baron_20131019_ok.ml]. *)

module Wrap__Content = struct
  module F = struct type t end
  module D = struct type t end
end;;

module Wrap = struct
  module Content = Wrap__Content
end;;

open Wrap;;

(* The expected inferred signature of [Make] is
     (DorF : sig type t end) -> sig end
   i.e. with [t] kept abstract, NOT
     (DorF : sig type t = Content.F.t end) -> sig end
   which would prevent applying [Make] to [Content.D]. *)
module Make (DorF : module type of Content.F) = struct end;;

module M_F = Make (Content.F);;
module M_D = Make (Content.D);;

[%%expect{|
module Wrap__Content :
  sig module F : sig type t end module D : sig type t end end
module Wrap : sig module Content = Wrap__Content end
module Make : (DorF : sig type t end) -> sig end
module M_F : sig end
module M_D : sig end
|}]

(* Module ascriptions still strengthen (per gatien_baron_20131019_ok.ml). *)

module Std2 = struct module M = struct type t end end;;
module Std' = Std2;;
module M' : module type of Std'.M = Std2.M;;
let f3 (x : M'.t) = (x : Std2.M.t);;

[%%expect{|
module Std2 : sig module M : sig type t end end
module Std' = Std2
module M' : sig type t = Std2.M.t end
val f3 : M'.t -> Std2.M.t = <fun>
|}]
