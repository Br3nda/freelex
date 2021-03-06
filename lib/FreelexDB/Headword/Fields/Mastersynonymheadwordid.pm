sub format_mastersynonymheadwordid_form {
   my $self = shift;
   my $c = shift;
   if (ref $self) {
      return $self->format_master_form_proto($c,'synonym')
   }
   else { return fltextbox("mastersynonymheadwordid","") }
}

sub format_mastersynonymheadwordid_plain {
   my $self = shift;
   if (ref $self) {
      return "" unless $self->mastersynonymheadwordid;
      return FreelexDB::Globals->master_synonym_ref_chars->[0] . $self->printedreference($self->mastersynonymheadwordid->headwordid) . FreelexDB::Globals->master_synonym_ref_chars->[1];
   }
}

sub postdisplay_mastersynonymheadwordid {
   my $self = shift;
   return $self->postdisplay_master_proto('synonym');
}

sub validate_mastersynonymheadwordid {
   my $self = shift;
   return ($self->masterformat('synonym'),$self->masterrecursion('synonym'))
}

sub post_update_mastersynonymheadwordid {
   my $self = shift;
   my $c = shift;
   my $type = 'synonym';

   $self->post_update_makememaster_proto($c, $type);
   return;
}

1;
      

   
     
      
         