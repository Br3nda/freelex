#!/usr/bin/perl;

package FreelexDB::Headword::Base;
  
  use base 'FreelexDB::DBI';
  use strict;
  
  use FreelexDB::Globals ();
  use FreelexDB::Utils::Format;
  use FreelexDB::Utils::Entities;
  use FreelexDB::Utils::Validation;
  use FreelexDB::Utils::Synonyms;
  use FreelexDB::Utils::Mlmessage;

  
  use Carp  qw(croak cluck);
  
  freelex_entities_init();
  use Data::Dumper;

sub external_fields { return ['HEADWORDTAGS'] }

sub display_order_form {
   return ['headword','headwordid','variantno','gloss','symbol','binomial','synonyms','HEADWORDTAGS','definition','essay','english','example', 'relatedterms','detailedexplanation','neweditorialcomment','owneruserid','CREATEUSERANDDATE','UPDATEUSERANDDATE'];
}

sub pseudo_cols {
   return grep {  $_ eq uc($_) } @{FreelexDB::Headword->display_order_form};
}

sub display_order_print {
   return ['headword','variantno','headwordid','gloss','symbol','binomial','synonyms','definition','essay','english','example','relatedterms','detailedexplanation'];
}

sub search_result_cols { return ['headword','headwordid','gloss','definition','example','owneruserid'] }

sub search_include_other_cols { return 
['gloss','symbol','definition','example','english','essay','detailedexplanation','relatedterms','source']
}

sub format { 
   my $self = shift;
   $self = shift   if (!ref $self && $self =~ /FreelexDB\:\:Headword$/);
   my $col = shift;
   my $formatmode = shift || 'plain';
   my @other_args = @_;
   my $val = "";
   if ((ref $self) && ($self->find_column($col))) {
#      die $col . $formatmode . $self->$col . Dumper($self)    if $col eq 'gloss';
      $val = $self->$col
   }

   my $result = "";
   
   my $format_func_type = 'format_' . $col . '_' . $formatmode . '_type';
   
   if (defined &$format_func_type) {
      #
      # is it a tag?
      #

      my $type = eval('&'.$format_func_type);
      cluck "Error in function $format_func_type:" . $@      if $@;
      if ( my @tags = $type =~ /\s*\<([^\s\>]+)(?:\s|\>)/g) {
         $result =  entityise($type . $val) . '</' . join('></',reverse @tags) .  '>';
      }
      
      elsif ($type eq 'textarea') {
         $result =  fltextarea($col,$val);
      }
      elsif ($type eq 'textbox') {
         $result =  fltextbox($col,$val);
      }
      elsif ($type eq 'fckeditor') {
         $result =  flfckeditor($col,$val)
      }
      
      else { die "unknown format type $type for $format_func_type" }
   }
   
   else {
      my $format_func_name = 'format_' . $col . '_' . $formatmode;
      if (defined &$format_func_name) {
         my $ffnresult = eval('&'.$format_func_name.'($self,@other_args)');
         cluck "Error in function $format_func_name:" . $@      if $@;

         $result =  $ffnresult || "";
#      return $ffnresult;
      }
      elsif ($formatmode ne 'plain') {
         my $format_func_plain_name = 'format_' . $col . '_plain';

         if (defined &$format_func_plain_name) {
            $result =  eval('&'.$format_func_plain_name.'($self,@other_args)');
            cluck "Error in function $format_func_plain_name:" . $@      if $@;
         }
         else {
            $result = $val
         }
      }
      else {
         $result =  $val
      }
   }

   return substitute_references($result, $formatmode);
}

sub substitute_references {
   my $val = shift;
   my $formatmode = shift || "";
   return "" unless defined $val  && $val;
   
   $val =~ s/\@\@.+?\-([0123456789]+)\@\@/&sr_replace($1,$formatmode)/ge;  


   
   return $val;
}

sub sr_replace {
   my $hwid = shift;
   my $formatmode = shift;
   my $result = "";
   
#   print STDERR join(':',$hwid,$formatmode),"\n";
   
   if (my $hw = FreelexDB::Headword->retrieve($hwid)) {  
      if ($formatmode eq 'form') {
         $result =  '@@' . $hw->headword . '-' . $hwid . '@@'
      }
      elsif ($formatmode eq 'print') {
#         $result = '<!-- ref:' . $hwid . ' -->' . '<b>' . $hw->headword . '<b>' . '<!-- end ref -->';
          my $hwref = $hw->headword;
          if (defined $hw->variantno  &&  $hw->variantno) {
              $hwref .= '<sup>' . $hw->variantno . '</sup>';
          }
          $result = '<b>' . $hwref . '</b>'; 
      }
      else {
#         $result = '<!-- ref:' . $hwid . ' -->' . '<a href="../../headword/display?_id=' . $hwid . '&_nav=no" target="_blank">' . $hw->headword . '</a>' . '<!-- end ref -->';
          $result = '<b>' . '<a href="../headword/display?_id=' . $hwid . '&_nav=no" target="_blank">' . $hw->headword . '</a>' . '</b>'
      }
   }
   else { # no headword with that ID 
      if ($formatmode eq 'form') {
         $result = '@@' . 'ERROR no headword with id-' . $hwid . '@@';
      } 
      else {
           $result = '<font color="#ff0000">error: no headword with id-<b>' . $hwid . '</b></font>';
      }
   }
#   print STDERR $result, "\n";
   return $result;   
}

#sub dereference {
#   my $self = shift;
#   my $val = shift || return;
#   $val =~ s/\<\!\-\- ref\:(\d+) \-\-\>.*?\<\!\-\- end ref \-\-\>/\#\#$1\#\#/sg;
#   $val =~ s/\#\#.*?\-(\d+)\#\#/\#\#$1\#\#/sg;
#   return $val;
#}
   

sub rowtohashref {
   my $self = shift;
   my $archivecopy = {};
   foreach my $ac (FreelexDB::Hwarchive->all_columns) {
     if (defined $self->get($ac)) {
        $archivecopy->{$ac} = $self->get($ac)   
     }
   }
   return $archivecopy;
}


sub canupdate {
   my $self = shift;
   my $user = shift;
   
   return 0 unless $user->get('canupdate');
   return 1 if $self->owneruserid = $user->get('matapunauserid');
   return 1 if $user->get('editor');
   return 0;  
}
   

sub no_write_access {
     my $self = shift;
     my $c = shift;
     my $message = "";
     return 0 if $c->user->get('sysadmin');
     if (!$c->user->get('canupdate')) {
       $message = mlmessage('no_write_access',$c->user->get('lang'));
       return $message;
     }
     return 0 unless ($self && ref $self && $self->lifecycleid);
     if ($self->lifecycleid == FreelexDB::Globals->lifecycle_complete) {
       $message =  mlmessage('cant_update_lifecycle_complete',$c->user->get('lang'));
       return $message;
     }
     return 0;
}


sub validate {
   my $self = shift;
   my $col = shift;
   my $c = shift || "";
   my $validate_sub_name = 'validate_' . $col;   
   if (defined &$validate_sub_name) {
      return eval('&'.$validate_sub_name.'($self,$c)');
    }
   else {
      return ();
   }
}

sub preupdate {
   my ($self, $col, $c) = @_;
   my $pre_update_sub_name = 'pre_update_' . $col;   
   if (defined &$pre_update_sub_name) {
      $self->$pre_update_sub_name($c);
   }
}


sub postupdate {
   my ($self, $col, $c) = @_;
   my $post_update_sub_name = 'post_update_' . $col;   
   if (defined &$post_update_sub_name) {
      $self->$post_update_sub_name($c);
   }
}
         

sub clone {
   my ($self, $col, $c) = @_;
   my $post_update_sub_name = 'clone_' . $col;   
   if (defined &$post_update_sub_name) {
      $self->$post_update_sub_name($c);
   }
}


sub use_headword_fields {
   my @dir = FreelexDB::Globals->headword_fields_dir();
   my %loaded = ();
   foreach my $dir (@dir) {
      opendir(DIRHANDLE,$dir) || die "Couldn't open directory $dir: $!\nCheck FreelexDB::Globals->headword_fields_dir value";
      my @files = readdir DIRHANDLE;
      foreach my $f (@files) {
         next unless (my $fname) = $f =~ /^(.+)\.pm$/; 
         next if exists $loaded{$fname};
         $loaded{$fname} = 1;
         my $modname = 'FreelexDB::Headword::Fields::' . $fname;
         eval "use $modname ()";
         if ($@) { croak "error using $modname:" . $@ }
      }
      close DIRHANDLE;
   }
}

sub postdisplay {
   my $self = shift;
   my $col = shift;
   my $postdisplay_sub_name = 'postdisplay_' . $col;   
   if (defined &$postdisplay_sub_name) {
      return eval('&'.$postdisplay_sub_name.'($self)');
   }
   else {
      return;
   }
}


  1;
